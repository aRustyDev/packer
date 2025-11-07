---
title: QED
deprecated: true
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# QED

- QED (QEMU Enhanced Disk) – abandoned; use QCOW2.

## Status

Deprecated / obsolete. Retained only for historical reference. Modern QEMU builds still recognize QED for backward compatibility, but new image creation should use `qcow2`.

## Original Rationale

QED was introduced aiming for:

- Improved performance over early `qcow2` (at the time).
- Simpler metadata structures.
- Faster snapshot handling.

Subsequent `qcow2` enhancements (lazy refcounts, improved caching, extended L2 tables, better corruption handling) eliminated QED’s advantages.

## Key Limitations

| Aspect             | QED                   | Modern QCOW2                                   |
| ------------------ | --------------------- | ---------------------------------------------- |
| Ecosystem adoption | Very low              | Ubiquitous                                     |
| Feature evolution  | Stagnant              | Actively maintained                            |
| Tooling support    | Minimal (legacy only) | Broad (libvirt, clouds, orchestration)         |
| Snapshot semantics | Basic                 | Mature (internal + external overlay workflows) |
| Extensibility      | Constrained           | Ongoing feature flags                          |

## Migration

Convert any lingering QED disks to `qcow2` (preferred) or `raw`:

```
qemu-img convert -p -O qcow2 legacy.qed migrated.qcow2
qemu-img convert -p -O raw legacy.qed disk.raw
```

Then validate:

```
qemu-img check migrated.qcow2
```

## When You Might Still Encounter It

- Old lab archives.
- Outdated documentation or academic material.
- Legacy VM artifacts in backup vaults.

Treat as a candidate for immediate conversion if operational reuse is required.

## Recommendation

Do not create new QED images. Standardize on:

- `qcow2` for featureful copy‑on‑write workflows.
- `raw` (optionally on LVM/ZFS/Ceph) for maximum performance and simplicity.

## Summary

QED was a transitional experiment that lost relevance once `qcow2` performance and reliability improved. Convert and retire; avoid incorporating QED into any contemporary build, distribution, or CI pipeline.
