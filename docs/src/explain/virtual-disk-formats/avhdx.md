---
title: AVHDX
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# AVHDX (Hyper‑V Differencing / Checkpoint Disk for VHDX)

`AVHDX` files are differencing (delta) virtual disk layers created by Hyper‑V when a checkpoint (snapshot) is taken of a VM that uses one or more `VHDX` base disks. Each `.avhdx` captures only changed blocks relative to its parent (a base `.vhdx` or an earlier `.avhdx`), enabling point‑in‑time rollback or backup workflows without duplicating the entire disk.

Unlike legacy `AVHD` (for VHD), `AVHDX` inherits all resiliency and scalability improvements of the VHDX format (metadata journaling, >2 TB disk sizes, 4K sector alignment support).

## Purpose

- Provide point‑in‑time capture of disk state for rollback (testing, patching).
- Facilitate application‑consistent checkpoints (with VSS integration in Windows guests).
- Enable backup solutions to extract changed data efficiently (export, block change tracking via external tooling).
- Support short‑lived “Production” or “Standard” checkpoints in day‑to‑day operations.

## Checkpoint Types (Hyper‑V)

| Type       | Contents                                                    | Use Case                                     |
| ---------- | ----------------------------------------------------------- | -------------------------------------------- |
| Standard   | Disk state (AVHDX), VM memory state, device state           | Fast rollback including in‑RAM application   |
| Production | Disk state only (VSS or file‑system flush; no memory state) | Safer for app consistency; preferred in prod |

Memory/state files are separate (`.vmrs`, `.vmcx`, sometimes `.bin`). The `.avhdx` only stores disk deltas.

## Chain Structure

```
base.vhdx  <--  checkpoint1.avhdx  <--  checkpoint2.avhdx (active)
```

- Reads traverse downward until the block is found.
- Writes always go to the topmost (active) AVHDX layer.
- Deep chains increase read latency; keep depth shallow (≤3 recommended).

## Resiliency Advantages vs Legacy AVHD

| Aspect                  | AVHD (VHD era)         | AVHDX (VHDX era)                           |
| ----------------------- | ---------------------- | ------------------------------------------ |
| Max parent disk size    | 2 TB                   | 64 TB                                      |
| Metadata journaling     | None                   | VHDX journaling reduces corruption risk    |
| 4K logical sector       | Unsupported            | Supported                                  |
| Crash recovery behavior | Higher corruption risk | Log replay ensures consistent BAT/metadata |
| Recommended production  | Deprecated             | Supported (with lifecycle discipline)      |

## Lifecycle Operations

| Operation         | Description                                                        | Command / Tool (Examples)                                   |
| ----------------- | ------------------------------------------------------------------ | ----------------------------------------------------------- |
| Create checkpoint | Generates new `.avhdx` per attached VHDX                           | `Checkpoint-VM -Name MyVM -SnapshotName BeforePatch`        |
| List chain        | Enumerates VHDX / AVHDX relationships                              | `Get-VHD -Path disk.vhdx` (ParentPath / VhdType fields)     |
| Apply (rollback)  | Revert active layer to chosen checkpoint; creates new active delta | Hyper‑V Manager GUI or `Restore-VMSnapshot`                 |
| Delete checkpoint | Merges delta into parent (consolidation)                           | `Remove-VMSnapshot -VMName MyVM -Name BeforePatch`          |
| Merge manually    | Offline merge of differencing disk chain                           | `Merge-VHD -Path child.avhdx -DestinationPath merged.vhdx`  |
| Convert base      | Flatten to standalone VHDX (no differencing)                       | `qemu-img convert -O vhdx base-with-deltas.vhdx final.vhdx` |
| Shrink space      | Run guest TRIM, then merge/defragment chain                        | Guest `fstrim`, then consolidation                          |

## Internal Mechanics (Conceptual)

- Each AVHDX stores:
  - Parent locator entries (metadata region) pointing to the parent disk.
  - Block allocation table (BAT) tracking which blocks are overridden.
  - Data blocks containing changed sectors.
- On read:
  1. Hyper‑V queries top BAT.
  2. If block absent, moves to parent.
  3. Continues until data found or root base disk reached.
- On consolidation:
  - Changed blocks are written into the parent; intermediate deltas removed.
  - Metadata/log journaling ensures atomic updates.

## Performance Considerations

| Factor               | Impact / Guidance                                                  |
| -------------------- | ------------------------------------------------------------------ |
| Chain depth          | Each additional layer adds lookup overhead; consolidate early.     |
| I/O pattern          | Heavy random reads penalized more by deep chains than sequential.  |
| Storage backend      | High IOPS (NVMe, SSD) masks some layering cost; still limit depth. |
| Consolidation timing | Large merges can stun VM I/O; schedule during low traffic window.  |
| Disk size            | Larger disks amplify consolidation duration; prune proactively.    |
| TRIM/UNMAP           | Ensure guest TRIM and host discard to reclaim space post deletes.  |

## Best Practices

| Practice                                          | Rationale                                     |
| ------------------------------------------------- | --------------------------------------------- |
| Keep checkpoint lifetime short (hours/days)       | Reduces chain growth & corruption window      |
| Use Production checkpoints for critical workloads | Avoids relying on volatile memory state       |
| Limit depth (prefer ≤3 active deltas)             | Preserves predictable read performance        |
| Consolidate before backups / export               | Simplifies restore & portability              |
| Never hand‑edit AVHDX metadata                    | Prevents chain breakage / unrecoverable state |
| Automate pruning (CI/CD pipelines)                | Prevents “forgotten” long‑lived snapshots     |
| Validate after merges (boot & app smoke tests)    | Ensures integrity before deleting old images  |

## Common Pitfalls

| Pitfall                                                | Consequence                                         | Mitigation                                           |
| ------------------------------------------------------ | --------------------------------------------------- | ---------------------------------------------------- |
| Long‑term retention of many checkpoints                | Performance degradation, longer consolidation       | Enforce retention policy                             |
| Deleting large chain during peak usage                 | VM stun / noticeable latency spike                  | Schedule consolidation off‑peak                      |
| Relying on Standard checkpoint for production rollback | App inconsistent state after revert                 | Prefer Production checkpoint                         |
| Manual file manipulations (rename/move)                | Broken parent locator → boot failures               | Use Hyper‑V Manager / PowerShell only                |
| Ignoring guest TRIM                                    | Bloated delta size (unused blocks remain allocated) | Run `fstrim -av` (Linux) / defrag/Optimize (Windows) |
| Excessive nested checkpoints in automated tests        | Sluggish CI VMs                                     | Flatten after each test cycle                        |

## Space Reclamation Workflow (Example)

1. Inside guest (Linux):
   ```
   fstrim -av
   ```
   or create/delete a zero file to encourage discard.
2. Remove unneeded checkpoints:
   ```
   Remove-VMSnapshot -VMName MyVM -Name OldCheckpoint
   ```
3. If chain remains deep:
   - Consolidate sequentially or clone the VM to a fresh base VHDX.

## Migration from Legacy AVHD

| Step | Action                                     | Purpose                            |
| ---- | ------------------------------------------ | ---------------------------------- |
| 1    | Delete / apply old AVHD snapshots          | Flatten legacy chain               |
| 2    | Convert base VHD to VHDX                   | Gain resiliency & size features    |
| 3    | Create fresh Production checkpoint (AVHDX) | Establish modern snapshot baseline |
| 4    | Validate workload performance & integrity  | Assure successful migration        |
| 5    | Archive legacy VHD/AVHD (optional)         | Retain for audit (read‑only)       |

PowerShell conversion example:

```
Convert-VHD -Path .\legacy.vhd -DestinationPath .\modern.vhdx
```

## Tooling Examples

Create Production checkpoint:

```
Checkpoint-VM -Name MyVM -SnapshotName PreUpdate -CheckpointType Production
```

List disks & parents:

```
Get-VHD -Path "C:\HyperV\VMs\MyVM\Virtual Hard Disks\disk.vhdx"
```

Merge differencing disk manually (offline scenario):

```
Merge-VHD -Path .\child.avhdx -DestinationPath .\merged.vhdx
```

Enumerate snapshots:

```
Get-VMSnapshot -VMName MyVM
```

Restore snapshot:

```
Restore-VMSnapshot -VMName MyVM -Name PreUpdate
```

## Backup Considerations

- App‑consistent backup: Prefer Production checkpoint + VSS (Windows guest) or filesystem quiesce (Linux).
- Always capture entire chain if not yet consolidated (base + all AVHDX layers).
- Post‑backup consolidation reduces future recovery complexity.

## When NOT to Use AVHDX Long-Term

| Scenario                                    | Alternative Strategy                    |
| ------------------------------------------- | --------------------------------------- |
| Version control of golden images            | Bake new VHDX (fresh build)             |
| Multi‑cloud portability artifact            | Export/convert to RAW / VHDX flattened  |
| Continuous integration test state retention | External provisioning + ephemeral disks |
| Tiered backup strategy (monthly retention)  | Full image export (flatten first)       |

## Security Notes

- AVHDX itself provides no encryption; rely on:
  - BitLocker / guest FS encryption.
  - Encrypted storage backend (e.g., Storage Spaces, SAN-level).
  - Host volume encryption (e.g., Windows EFS not typical; prefer BitLocker).
- Chain complexity complicates forensic review—flatten before long-term archival.

## Monitoring & Automation

| Metric / Check           | Why It Matters                            | Collection Method                              |
| ------------------------ | ----------------------------------------- | ---------------------------------------------- |
| Snapshot count           | Prevents runaway chain growth             | `Get-VMSnapshot`                               |
| Delta size growth        | Indicates write amplification             | File size on disk / storage monitoring         |
| Consolidation duration   | Capacity planning for maintenance windows | Timed merge operations / logs                  |
| I/O latency during merge | Detects performance impact                | Performance counters (Hyper-V storage metrics) |

Automate:

- Alert if snapshot count exceeds threshold.
- Schedule nightly pruning for stale test VMs.
- Integrate flattening into image promotion pipeline.

## Summary

`AVHDX` delivers modern, resilient differencing capabilities for Hyper‑V environments leveraging the VHDX format. It enables short‑term rollback and consistent application checkpointing while preserving large disk support and improved crash recovery. Proper lifecycle management—minimizing chain depth, preferring Production checkpoints for critical workloads, consolidating promptly, and flattening before distribution—ensures performance and reliability. Treat AVHDX layers as transient operational tools rather than permanent versioning mechanisms; maintain canonical, flattened VHDX images for portability and long-term archival.
