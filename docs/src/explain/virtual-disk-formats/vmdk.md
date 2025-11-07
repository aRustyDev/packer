---
title: VMDK
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# VMDK

`VMDK` (Virtual Machine Disk) is the family of virtual disk image formats used across VMware products (Workstation, Fusion, ESXi, vSphere, vCloud) and supported by a wide ecosystem of tooling. VMDK is a descriptor + one or more extent files holding guest block data.

## Key Characteristics

- Widely supported: native to VMware; convertible via `qemu-img`, `ovftool`, and others.
- Multiple subformats (monolithic, split, sparse, flat, stream-optimized) chosen for transport vs performance.
- Supports thin provisioning, snapshots (delta disks), changed block tracking (CBT), and storage policy integration.
- Can reside on different backing stores: VMFS datastores, vSAN objects, NFS datastores, local filesystems.

## High-Level Structure

A VMDK may consist of:

1. Descriptor file (plain text; may be embedded or separate): geometry, `createType`, adapterType, extents, CID (change id), parentCID (for snapshots), provisioning flags, etc.
2. One or more extent files: store actual block data (flat or sparse).

Example (simplified descriptor excerpt):

```
# Disk DescriptorFile
version=1
encoding="UTF-8"
CID=abcd1234
parentCID=ffffffff
createType="monolithicSparse"
RW 83886080 SPARSE "disk-s001.vmdk"
ddb.adapterType = "lsilogic"
ddb.geometry.cylinders = "5221"
```

In split-disk forms there are multiple extents (commonly ~2 GB each).

## Common Subformats / createType Values

| Subformat (createType)   | Description                                      | Typical Use                                |
| ------------------------ | ------------------------------------------------ | ------------------------------------------ |
| monolithicFlat           | Single large preallocated extent + descriptor    | High performance, fewer files              |
| monolithicSparse         | Single-file sparse (thin) disk                   | Workstation / Fusion portability           |
| twoGbMaxExtentSparse     | Split sparse extents (≈2 GB each) + descriptor   | Legacy filesystem limits, easier transport |
| twoGbMaxExtentFlat       | Split preallocated extents                       | Historical compatibility                   |
| streamOptimized          | Compressed sparse format optimized for streaming | OVA/OVF export/import, distribution        |
| vmfs (flat + descriptor) | Flat extent on VMFS (can be thick or thin)       | ESXi production                            |
| sesparse (delta)         | Snapshot delta using SESparse                    | Efficient large-disk snapshots (≥5.5)      |
| vsanSparse               | vSAN object-based sparse delta                   | vSAN snapshot chains                       |

Additional provisioning qualifiers (not distinct createType): `eagerZeroedThick`, `lazyZeroedThick`, `thin`.

## Provisioning Modes

| Mode             | Allocation           | Zeroing Behavior       | Performance Notes                                        |
| ---------------- | -------------------- | ---------------------- | -------------------------------------------------------- |
| Thin             | On demand            | Zero on first write    | Saves space; initial writes pay allocation cost          |
| LazyZeroedThick  | Full space allocated | Zero on first write    | Faster create; first write penalty                       |
| EagerZeroedThick | Full space allocated | Fully zeroed at create | Best consistent latency; required for some FT/clustering |

## Snapshots (Delta Disks)

A snapshot creates a _delta_ VMDK referencing a _base_ (parent). Writes go to the delta; reads fall back through the chain. The descriptor records `parentCID`. Deep chains degrade performance (extra metadata lookups & random I/O overhead).

- Creation: base becomes read-only; new `*-delta.vmdk` created (sparse / sesparse / vsanSparse).
- Consolidation: merges delta changes back into base (I/O intensive; needs free space).
- Best practice: keep snapshot lifetime short (backups, patch windows).

## Changed Block Tracking (CBT)

CBT maintains a bitmap of changed blocks for incremental backups (stores data in `*-ctk.vmdk` files).

Considerations:

- Disable before disk extend/restore operations that alter layout.
- Reset CBT after manual chain repairs (force a new full backup).
- Validate backup software CBT integration on new storage tiers.

## streamOptimized Variant

- Produced during OVF/OVA export (e.g., via `ovftool` or vCenter).
- Compresses sparse regions for reduced transport size.
- Not tuned for direct runtime performance—intended only for distribution.
- Commonly converted/imported back to flat/thin layouts on target datastore.

## SESparse & vsanSparse

- `sesparse`: Optimized snapshot delta format for large disks and efficient space reclamation (space-efficient refcounting and block sharing).
- `vsanSparse`: Snapshot/replica semantics integrated with vSAN’s object-based storage & policy management.

## Descriptor Fields (Selected)

| Field           | Meaning                                                     |
| --------------- | ----------------------------------------------------------- |
| CID             | Change identifier for disk content (snapshot integrity)     |
| parentCID       | Expected CID of parent (validates snapshot chain)           |
| createType      | Subformat (e.g., `monolithicSparse`)                        |
| RW              | Logical size (sectors) + extent type + filename             |
| ddb.adapterType | Virtual controller type (`lsilogic`, `pvscsi`, `ide`, etc.) |
| ddb.uuid        | Disk UUID                                                   |
| ddb.geometry.\* | Legacy CHS hints (mostly historical)                        |

## Conversion Examples

RAW → VMDK (thin / monolithic sparse):

```
qemu-img convert -p -O vmdk -o subformat=monolithicSparse disk.raw disk.vmdk
```

RAW → VMDK (streamOptimized for OVA):

```
qemu-img convert -p -O vmdk -o subformat=streamOptimized disk.raw disk.vmdk
```

VMDK (sparse) → RAW:

```
qemu-img convert -p -O raw disk.vmdk disk.raw
```

Defragment / compact (recreate optimized sparse):

```
qemu-img convert -p -O vmdk disk.vmdk compacted.vmdk
```

## Performance Considerations

| Factor              | Guidance / Impact                                                         |
| ------------------- | ------------------------------------------------------------------------- |
| Provisioning        | EagerZeroedThick reduces first-write latency vs thin/lazy.                |
| Snapshot depth      | Keep chains shallow (≤2–3). Deep chains amplify read latency.             |
| Split vs monolithic | Split adds minimal overhead; used mainly for legacy FS constraints.       |
| Backend datastore   | VMFS vs NFS vs vSAN differ in latency/throughput; align layout with SLAs. |
| Grain size          | Affects delta efficiency; typically auto-managed by VMware.               |
| Consolidation IO    | Plan maintenance windows; ensure sufficient free space for merges.        |

## Best Practices

- Limit snapshot lifetime; monitor and consolidate proactively.
- Use EagerZeroedThick for latency-sensitive, clustered, or FT workloads.
- Only use streamOptimized for export; convert before production use.
- Tag/version base disks; avoid ambiguous “latest” without metadata.
- Enable CBT only when actually used (avoid unnecessary metadata churn).
- Validate backups by performing periodic full restore tests.
- Monitor thin growth; set datastore usage alarms.

## Common Pitfalls

| Pitfall                                  | Consequence                                   | Mitigation                                  |
| ---------------------------------------- | --------------------------------------------- | ------------------------------------------- |
| Long-lived snapshot chains               | Performance degradation, larger consolidation | Enforce retention policy & alerts           |
| Insufficient free space during merge     | Consolidation failure / VM stun               | Maintain capacity buffer (≥ largest delta)  |
| Using streamOptimized in production      | Suboptimal runtime performance                | Convert/import to standard flat/thin format |
| Ignoring CBT inconsistencies post-repair | Invalid incremental backups                   | Reset CBT & force full backup cycle         |
| Manually editing parentCID incorrectly   | Chain break / data loss risk                  | Use supported tools (`vmkfstools`, vSphere) |

## When NOT to Use VMDK

| Scenario                                        | Prefer                   |
| ----------------------------------------------- | ------------------------ |
| Native KVM/libvirt environment                  | QCOW2                    |
| Direct block passthrough / raw device           | RAW / block mapping      |
| Cloud-native image management (AMI/Azure/GCE)   | Cloud image abstractions |
| Analytics pipeline (no snapshots, heavy writes) | RAW on optimized storage |

## Interoperability

- `qemu-img` and VirtualBox can read many VMDK variants (monolithicSparse, streamOptimized).
- Advanced VMware-specific delta formats (SESparse, vsanSparse) may not retain semantics after conversion.
- Maintain a canonical RAW for multi-hypervisor pipelines; derive VMDK on demand.

## Security & Integrity

- No native at-rest encryption in the file format (encryption handled at VM/vSAN/storage layer or guest).
- Use hashing (SHA256) for artifact integrity; store descriptor + extent checksums.
- Snapshot chain integrity relies on consistent CID/parentCID values—avoid manual tampering.

## Operational Checks

| Task                    | Tool / Action                                |
| ----------------------- | -------------------------------------------- |
| Identify snapshot chain | vSphere UI / `vim-cmd vmsvc/snapshot.get`    |
| Inspect descriptor      | Open `.vmdk` text file (descriptor only)     |
| Verify CBT usage        | Check VM settings / presence of `*-ctk.vmdk` |
| Estimate delta growth   | Monitor datastore & `du` on paths (NFS)      |

## Summary

VMDK is a flexible, multi-variant disk format optimized for VMware environments, providing snapshotting, thin provisioning, CBT, and distribution-friendly variants (streamOptimized). Correct subformat selection (eager-zeroed vs thin, monolithic vs split), disciplined snapshot management, and cautious use of export variants are critical to sustaining performance and reliability. For interoperability, retain a RAW “source of truth” and regenerate VMDK as needed; for production performance, minimize snapshot depth and choose appropriate provisioning aligned with workload SLAs.
