---
title: Snapshotting
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# Copy-on-write / snapshot‑capable mechanisms

> These are either inherent features of a format or layering conventions:

- QCOW2 internal snapshot tree (images can chain via backing file references).
- VMDK snapshot chain (each snapshot creates a delta VMDK referencing a parent).
- VHD/VHDX differencing disks (parent-child relationship).
- AVHDX snapshot layers in Hyper‑V.
- Overlay files in libvirt/KVM using QCOW2 backing a RAW base.
  (These are not separate “formats” but capabilities that matter when choosing.)
