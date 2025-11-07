---
title: COW
deprecated: true
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# COW

- COW (Original QEMU copy-on-write disk format, sometimes referred to as `qcow v1`).
- Historical predecessor to QCOW and QCOW2; provides basic copy‑on‑write layering but lacks modern features (efficient snapshots, compression, encryption improvements).
- Obsolete: superseded by QCOW2 which offers better performance, reliability, and feature set.
- Recommendation: Do not use for new images; convert any lingering COW artifacts to QCOW2 or RAW (`qemu-img convert -O qcow2 old.cow new.qcow2`).
