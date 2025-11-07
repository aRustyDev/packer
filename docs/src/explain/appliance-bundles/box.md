---
title: BOX
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# BOX

- BOX: Packaging wrapper; inside may be VMDK/VDI/QCOW2/etc.
- **Vagrant BOX** (`.box`): TAR/ZIP bundle containing:
  - A metadata.json (provider, format)
  - One or more disk images (could be VMDK, VDI, QCOW2, etc, provider-dependent)
  - Provider-specific settings (VirtualBox .vbox, libvirt domain XML, etc).
