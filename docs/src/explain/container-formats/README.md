---
title: Container Formats
assumed_roles:
  - .aim/roles/techdocs-engineer.md
---

# Container Formats

## Non-VM but adjacent (avoid confusion)

- OCI / Docker container images: Layered filesystem diffs (tar archives + manifests), not block device images.
- LXC/LXD rootfs tarballs: System-level container rootfs; not a virtual disk format unless wrapped.
- Snap packages, Flatpak runtimes: Application-level distribution formats.
- WIM (Windows Imaging Format): File-based OS deployment, not a block virtualization runtime artifact unless expanded into a disk.
