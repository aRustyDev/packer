---
title: VHDX
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# VHDX (Virtual Hard Disk v2)

`VHDX` is the successor to the legacy `VHD` format for Microsoft Hyper-V. It addresses scalability, resiliency, and modern storage alignment needs (large sector drives, >2 TB capacity) while adding extensibility for future features. It is the preferred format for new Hyper-V deployments unless compatibility or external platform constraints (e.g., Azure fixed VHD upload) require VHD.

## Key Improvements Over VHD

| Aspect                        | VHD                           | VHDX                                       |
| ----------------------------- | ----------------------------- | ------------------------------------------ |
| Maximum virtual disk size     | 2 TB                          | 64 TB                                      |
| Metadata resiliency           | None (susceptible to crashes) | Journaling log region + structured replay  |
| Logical sector support        | 512 bytes only                | 512, 4K logical sector emulation           |
| Physical sector alignment     | Limited                       | Optimized for 4K and 512e / 4Kn devices    |
| Extensibility                 | Minimal                       | Flexible metadata region for future fields |
| Large disk efficiency         | Less efficient block mapping  | Improved BAT and block sizing options      |
| Trim/Unmap behavior           | Basic                         | Enhanced support (space reclamation)       |
| Protection against power loss | Weak                          | Hardened header/log design                 |

## Disk Types

VHDX, like VHD, supports:

- Fixed: Full logical size allocated immediately.
- Dynamic: Sparse; grows as blocks are written (thin provisioning).
- Differencing: Child (delta) disk referencing a parent (for snapshot layering or image derivation).

PowerShell examples:

- Fixed: `New-VHD -Path .\disk-fixed.vhdx -SizeBytes 100GB -Fixed`
- Dynamic: `New-VHD -Path .\disk-dyn.vhdx -SizeBytes 100GB -Dynamic`
- Differencing: `New-VHD -Path .\child.vhdx -ParentPath .\base.vhdx -Differencing`

qemu-img example:

```
qemu-img create -f vhdx disk.vhdx 40G
```

## Internal Structure (Conceptual)

A VHDX file is composed of:

1. File Header: Signature + pointers to regions.
2. Region Table: Identifies the two key regions:
   - Metadata Region
   - Log Region (journaling layer for crash recovery)
3. Metadata Region: Contains entries defining virtual disk layout (block size, logical sector size, physical sector size, parent locator info for differencing disks).
4. Block Allocation Table (BAT): Maps logical blocks to file offsets.
5. Data Blocks: Actual guest data (allocated on demand for dynamic disks).
6. Log Region: Sequential log records capturing metadata update intent (replayed after abnormal termination).

Resiliency sequence (simplified):

- Metadata update intent written to Log Region.
- BAT / metadata updated.
- Log marked completed.
- On crash: Replay any incomplete sequences to ensure consistent BAT + metadata state.

## Block & Sector Sizes

- Default block size: Typically 32 MB for VHDX dynamic disks (configurable).
- Logical sector size (exposed to guest): 512 B or 4K (choose 4K where OS and workload support it).
- Physical sector size (host alignment guidance): 4K alignment reduces RMW penalties on modern disks.
- Choosing block size:
  - Larger blocks: Better for large sequential I/O (DB bulk loads, data warehousing).
  - Smaller blocks: Better space efficiency with many small random writes (but increases BAT overhead).

Set custom block size (Hyper-V PowerShell):

```
New-VHD -Path .\data.vhdx -SizeBytes 200GB -Dynamic -BlockSizeBytes 16MB
```

## Dynamic vs Fixed Trade-offs

| Criteria            | Dynamic VHDX                             | Fixed VHDX                                   |
| ------------------- | ---------------------------------------- | -------------------------------------------- |
| Initial size        | Small (metadata only)                    | Full logical size upfront                    |
| Space efficiency    | High (thin provisioning)                 | Low (preallocated)                           |
| Fragmentation risk  | Higher (allocation over time)            | Lower (contiguous if filesystem cooperates)  |
| Creation time       | Fast                                     | Slower (must allocate full space)            |
| Predictable latency | Slight overhead for new block allocation | More predictable (no growth events)          |
| Best use cases      | Dev/test, variable growth workloads      | Performance-sensitive, capacity-planned prod |

Mitigation for dynamic fragmentation:

- Periodic conversion (defragment): `qemu-img convert -O vhdx dyn.vhdx compacted.vhdx`
- Ensure host filesystem supports efficient sparse allocation (NTFS on properly aligned storage).

## Differencing Chains

- Each differencing VHDX stores a parent locator (metadata entries) and references unchanged blocks from parent.
- Chains longer than ~2–3 layers degrade random read performance due to lookup traversal.
- Best practice: Flatten (merge) chains before long-term archival or production deployment.

Merging (Hyper-V):

```
Merge-VHD -Path .\child.vhdx -DestinationPath .\merged.vhdx
```

Flatten with qemu-img:

```
qemu-img convert -O vhdx child.vhdx merged.vhdx
```

## Trim / UNMAP (Space Reclamation)

When the guest OS deletes data and issues TRIM/UNMAP:

- Hyper-V passes discard hints to underlying storage.
- Dynamic VHDX freed blocks become unallocated (host file shrinks or leaves holes).
- Ensure:
  - Guest filesystem mounted with discard (Linux: use fstrim periodically).
  - Storage backend (e.g., ReFS/NTFS + thin storage array) honors punch-hole semantics.

Manual reclamation inside guest (Linux):

```
fstrim -av
```

## Resiliency & Crash Recovery

- Metadata journaling prevents inconsistent BAT after power loss.
- On open, Hyper-V replays the log region to restore a coherent state.
- Better protection versus VHD where abrupt termination could yield partial metadata writes and chain corruption.

Recommended:

- Avoid manipulating VHDX with unsupported tools (raw hex editors).
- Use `Repair-VHD` (PowerShell) for limited recovery scenarios.

## Performance Considerations

| Factor                         | Guidance                                                                                |
| ------------------------------ | --------------------------------------------------------------------------------------- |
| Block size                     | Tune for workload patterns (large sequential vs many small writes).                     |
| Sector size (guest view)       | Use 4K for modern OS/app stacks; legacy OS may require 512 B logical sectors.           |
| Storage backend                | Place fixed VHDX on high-performance tiers (NVMe, RAID SSD) for latency-sensitive DB    |
| Fragmentation (dynamic growth) | Convert / defragment periodically if growth patterns are highly random.                 |
| Snapshot depth                 | Keep differencing depth shallow; consolidate regularly.                                 |
| Alignment                      | Ensure partitions in guest start at 1 MiB boundary (modern partitioning tools do this). |

## Creation & Conversion Examples

Create dynamic 80 GB:

```
qemu-img create -f vhdx dyn.vhdx 80G
```

RAW → VHDX:

```
qemu-img convert -p -O vhdx disk.raw disk.vhdx
```

QCOW2 → VHDX (for Hyper-V migration):

```
qemu-img convert -p -O vhdx source.qcow2 target.vhdx
```

Fixed (preallocated) via PowerShell:

```
New-VHD -Path .\fixed.vhdx -SizeBytes 120GB -Fixed
```

## Azure Interop Note

Azure requires a _fixed VHD_ (not VHDX) for custom image uploads. Migration pipeline:

1. Build base image as VHDX (dynamic or fixed) on Hyper-V.
2. Generalize the OS (Sysprep / waagent provisioning).
3. Convert to fixed VHD:
   ```
   qemu-img convert -p -O vpc -o subformat=fixed base.vhdx azure.vhd
   ```
4. Upload `azure.vhd` to Blob storage → create image resource.

Do not attempt direct VHDX upload; platform will reject it.

## Integrity & Validation

- Hash artifacts for distribution:
  ```
  sha256sum disk.vhdx > disk.vhdx.sha256
  ```
- Hyper-V validation:
  - Attach and run basic file system checks inside guest.
  - For differencing chains, verify parent path consistency before migration.

## Backup & Replication

- Changed Block Tracking is implemented at Hyper-V level (not inside VHDX format directly).
- Use host-level backup solutions supporting VSS writers for application-consistent snapshots.
- Off-host conversion for deduplication: Convert dynamic VHDX to a compressed archive (e.g., .tar.gz) for cold storage.

## When to Prefer Alternatives

| Scenario                                         | Prefer RAW / Other Format                             |
| ------------------------------------------------ | ----------------------------------------------------- |
| Pure KVM / libvirt environment                   | QCOW2 or RAW                                          |
| Cloud-native AMI / GCE workflows                 | RAW / QCOW2 / VMDK depending on provider import rules |
| Direct block device performance optimization     | RAW on LVM / ZFS zvol / Ceph RBD                      |
| Cross-hypervisor interchange (OVF/OVA packaging) | StreamOptimized VMDK inside OVA                       |
| Minimalistic image pipeline with custom layering | RAW + overlay formats (external snapshot management)  |

## Common Pitfalls

| Pitfall                                  | Impact                                     | Mitigation                                                   |
| ---------------------------------------- | ------------------------------------------ | ------------------------------------------------------------ |
| Excessive differencing depth             | Read latency, consolidation complexity     | Consolidate early; avoid long-lived multi-layer chains       |
| Using dynamic for latency-critical DB    | Allocation overhead under write bursts     | Use fixed + eager provisioning on fast storage               |
| Ignoring TRIM support                    | Disk file balloons unnecessarily           | Enable guest fstrim / discard and host support               |
| Misaligned partitions (rare today)       | RMW penalties on 4K physical sector drives | Use modern partition tools (parted, diskpart, Windows Setup) |
| Converting to Azure without fixed format | Upload/import failure                      | Convert to fixed VHD before Azure pipeline                   |
| Manual tampering with header / metadata  | Corruption and unrecoverable disk          | Use supported tooling only                                   |

## Best Practices Summary

- Default to VHDX for Hyper-V unless external constraints dictate otherwise.
- Use fixed VHDX for predictable high-performance workloads; dynamic for flexible lab/dev scenarios.
- Keep differencing chains shallow; flatten for production or archival.
- Enable and verify discard/TRIM for thin provisioning efficiency.
- Version/tag images externally (filename, metadata) since format-level metadata is limited for custom fields.
- Maintain a canonical build pipeline: Source (RAW or QCOW2) → Hyper-V VHDX → Derived artifacts (Azure VHD, OVF packages, etc).

## Migration Strategy (Legacy VHD to VHDX)

1. Inspect legacy VHD (`qemu-img info disk.vhd`).
2. Convert:
   ```
   qemu-img convert -p -O vhdx disk.vhd disk.vhdx
   ```
3. Validate inside a test VM (boot + application checks).
4. Decommission old VHD after backup retention period.

## Summary

VHDX delivers scalability (up to 64 TB), resiliency via metadata journaling, alignment optimizations for modern storage, and extensibility lacking in VHD. It is the recommended disk format for Hyper-V deployments, with dynamic and fixed provisioning choices balancing space efficiency and performance predictability. For external platform imports (Azure) or cross-hypervisor portability, convert appropriately (to fixed VHD or other required formats). Maintain disciplined differencing chain management, enable discard for thin provisioning, and integrate image versioning into your CI/CD pipeline for reliable lifecycle control.
