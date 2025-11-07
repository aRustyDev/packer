# Image Stores Explained

## Backend block/image stores (infrastructure-level “images”)

> These are not files you pass around easily, but they can serve as VM roots:

- Ceph RBD volumes (block objects) used directly by KVM/libvirt as disks.
- LVM logical volumes or ZFS zvols (raw block devices).
- Sheepdog, Gluster-backed volumes for QEMU.
- iSCSI / Fibre Channel LUNs presented as raw disks to hypervisors.
- NVMe namespaces / storage arrays snapshots (vendor-specific).
- These lack a portable “file” format but conceptually are VM images.
