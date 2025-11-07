---
title: AVHD
deprecated: true
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# AVHD (Legacy Hyper‑V Differencing / Snapshot Disk)

`AVHD` is the legacy differencing (delta) disk format created by early versions of Microsoft Hyper‑V when taking a snapshot (checkpoint) of a base `VHD`. Each AVHD stores only changed blocks while referencing its parent for unchanged data. It has been superseded by `AVHDX`, which pairs with `VHDX` and adds resiliency and scalability improvements.

## Purpose (Historical Role)

- Capture point‑in‑time disk state for rollback, testing, or backup workflows.
- Enable short‑lived “checkpoints” during patching or application upgrades.
- Support differencing chains: base.vhd → child.avhd → child2.avhd (etc).

AVHD was never intended for long-term production retention or deep chains.

## Structure (Conceptual)

- Parent pointer: References a base VHD (or another AVHD).
- Block allocation table: Marks which blocks are overridden in the differencing layer.
- Sparse storage: Only modified blocks consume space.
- Read path: Hyper‑V traverses the chain from newest AVHD backward until data is found.

## AVHD vs AVHDX (Why It’s Deprecated)

| Aspect                   | AVHD (legacy)            | AVHDX (current)                          |
| ------------------------ | ------------------------ | ---------------------------------------- |
| Parent format            | VHD                      | VHDX                                     |
| Max virtual disk size    | Inherits VHD 2 TB limit  | Up to 64 TB (VHDX base)                  |
| Resiliency               | No metadata journaling   | Improved journaling / crash consistency  |
| Sector alignment         | 512 logical sectors only | 512 & 4K logical sector compatibility    |
| Corruption risk on crash | Higher                   | Lower (log replay)                       |
| Feature headroom         | Minimal                  | Extensible metadata regions              |
| Recommended usage        | None (migration advised) | Active differencing / modern checkpoints |

## Operational Limitations

- Susceptible to corruption during unexpected host power loss or crash.
- Performance degradation with deep chains (extra block lookups).
- Limited scalability (inherits VHD size ceiling).
- Lacks modern integrity and alignment optimizations found in AVHDX/VHDX.

## Migration Strategy (AVHD → VHDX / AVHDX)

1. Consolidate snapshots:
   - In Hyper‑V Manager or PowerShell: apply or delete checkpoints to merge AVHD layers back into the base VHD.
2. Convert base VHD to VHDX:
   ```
   Convert-VHD -Path .\base.vhd -DestinationPath .\base.vhdx
   ```
3. Create new checkpoints (will produce AVHDX):
   - Use modern Hyper‑V (Windows Server 2012+ / current versions).
4. Validate workload (boot + application tests).
5. Retire old VHD/AVHD artifacts after backup retention window.

## Best Practices (If Encountered)

| Recommendation                                | Rationale                                      |
| --------------------------------------------- | ---------------------------------------------- |
| Keep chains shallow (≤2) before consolidation | Minimizes read amplification / repair effort   |
| Avoid long‑term retention of AVHD layers      | Reduces corruption window                      |
| Never manually edit AVHD headers              | Prevents irreversible chain break              |
| Perform consolidation before backup/export    | Ensures complete, consistent disk image        |
| Convert base VHD to VHDX promptly             | Gains resiliency and size/performance benefits |
| Monitor free space during merge operations    | Consolidation needs writable headroom          |

## Common Pitfalls

| Pitfall                               | Consequence                                | Mitigation                                      |
| ------------------------------------- | ------------------------------------------ | ----------------------------------------------- |
| Deep unchecked snapshot chains        | Sluggish I/O, elevated merge time          | Enforce snapshot lifecycle policy               |
| Manual file moves/renames of AVHD     | Broken parent linkage → boot failure       | Use Hyper‑V tools only                          |
| Leaving AVHD in production for weeks  | Increased corruption / performance risk    | Consolidate after change validation             |
| Host crash mid‑snapshot operation     | Possible metadata inconsistency            | Run integrity checks; migrate to VHDX afterward |
| Backing up only the latest AVHD layer | Incomplete restore (missing parent blocks) | Back up entire chain or flatten first           |

## Validation & Recovery Notes

- Use PowerShell (`Get-VHD`) to inspect parent links.
- If chain corruption is suspected, attempt consolidation in Hyper‑V Manager.
- For critical workloads: restore from last full backup rather than risky manual repair.

## When To Treat As Artifact Only

If AVHD disks exist solely in archival exports of legacy environments, keep them immutable, document their origin, and prioritize conversion before any reuse.

## Summary

AVHD is a legacy differencing disk format tied to VHD-era Hyper‑V snapshots. It lacks the resiliency, size scalability, and sector alignment flexibility of AVHDX/VHDX. Any active reliance on AVHD should be phased out: consolidate, convert the base to VHDX, and adopt AVHDX for modern checkpoint workflows. Retain AVHD only as a historical artifact—do not generate new AVHD layers in contemporary virtualization pipelines.
