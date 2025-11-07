---
title: Image Format Selection
assumed_roles:
  - .aim/roles/techdocs-engineer.md
---

# Image Format Selection

## Selection criteria summary (how to pick a format)

> When choosing a VM disk or appliance format, consider:

- **Portability**: OVF/OVA, Vagrant BOX, RAW for universal conversion.
- **Feature needs**: Snapshots & backing chains (QCOW2, VMDK, VHDX differencing).
- **Performance**: RAW often fastest (no indirection); thin-provisioned sparse formats can fragment.
- **Space efficiency**: QCOW2/VMDK sparse; compression possible (QCOW2 internal or external).
- **Streaming/distribution**: VMDK streamOptimized, OVA (single file), “box” archives, AWS AMI import pipeline.
- **Cloud platform requirement**: Azure wants fixed-size VHD; AWS import expects RAW/VMDK; GCE supports RAW/QCOW2/VMDK/VHD.
- **Maximum size & resiliency**: VHDX vs older VHD; QCOW2 vs QED; features like TRIM/discard handling.
- **Tooling ecosystem**: qemu-img convert supports: raw, qcow2, qcow, vdi, vmdk, vhd, vhdx, qed, cloop, dmg, parallels, iscsi, rbd, sheepdog, nbd, luks, vpc (depending on build).
- **Snapshot model**: Internal (QCOW2) vs external delta chain (VMDK, VHDX differencing, AVHDX).
- **Encryption**: QCOW2 (LUKS layer), VMware vSphere VM-level encryption (policy-driven, not disk format), external storage encryption (Ceph, LUKS on raw).
- **Integrity & crash resiliency**: VHDX journaling vs simpler formats.
