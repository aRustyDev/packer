# Contexts

Below is a structured survey of the major (and many minor) virtual machine image and virtual disk formats, plus related packaging and metadata artifacts.

I’ve grouped them to differentiate (its totally natural to mix these up)

- “disk image”
- “appliance bundle”
- “cloud identifier”
- “supporting metadata”

High-level categories:

1. Installation / distribution media
2. Virtual disk (block device) formats
3. Copy‑on‑write / snapshot‑capable variants
4. VM/appliance packaging formats
5. Cloud provider image abstractions
6. Hypervisor / VM configuration & snapshot metadata
7. Backend block/image stores (not file formats per se, but used as VM “images”)
8. Deprecated / niche formats
9. Non-VM but adjacent (container & rootfs images)
10. Selection criteria summary

---

## Installation / distribution media

- **ISO**: Optical disk filesystem (usually bootable El Torito + ISO9660 + Joliet/Rock Ridge). Used to install or live-boot an OS; not a VM disk image of an installed system.
- **PXE/netboot artifacts**: Kernel (ELF/bzImage) + initrd (cpio/gzip) + squashfs or rootfs. Not a single “image format” but sometimes confused with them.
- **IMG** (ambiguous): Often a raw, byte-for-byte capture of a whole disk or partition, sometimes with an MBR/GPT. People call any raw byte stream “.img”.

---

## Virtual disk (block device) formats (core persistent storage)

> These store the contents of a virtual hard disk. Some are simple, some add metadata/features.

- **RAW**: Just a flat byte-for-byte representation. Highest compatibility, fast, no features (no internal snapshots, no compression). Sometimes sparse at filesystem level.
- **QCOW2**: QEMU copy-on-write v2. Supports internal snapshots, compression, encryption (depending on version), backing files, sparse allocation.
- **VMDK** (VMware Virtual Disk): Multiple variants: monolithicFlat, monolithicSparse, twoGbMaxExtentSparse, streamOptimized (for distribution), thin/thick on VMFS. Supports snapshots via delta disks.
- **VHD**: Original Microsoft/Connectix format. 2TB limit, fixed, dynamic, and differencing variants.
- **VHDX**: Successor to VHD (up to 64TB, better resiliency, larger logical sector sizes, metadata).
- **VDI**: VirtualBox native disk format. Supports dynamic allocation and snapshots (paired with VirtualBox metadata).
- **HDD** (Parallels): Parallels virtual disk file (often inside a .pvm bundle).
- **QED** (QEMU Enhanced Disk): Introduced as a successor to QCOW2; largely abandoned; superseded by improved QCOW2.
- **COW** (original QEMU COW / “qcow v1”): Historical predecessor to QCOW2.
- **DMG**: Apple disk image (HFS+/APFS); occasionally used to ship macOS installation media; not typical for generic VM runtime disks.
- **VMDK** “delta” files: Not a distinct format but important—differencing layers created for snapshots.
- **AVHD / AVHDX**: Hyper‑V differencing/snapshot disks (child layers referencing a base VHD/VHDX).

---

## VM / appliance packaging formats

> These bundle one or more disks plus configuration and metadata for portability.

- **OVF** (Open Virtualization Format): XML descriptor + referenced disk files (often VMDK, sometimes others) plus optional manifest (.mf) and certificate (.cert).
- **OVA**: Single TAR archive containing an OVF package (descriptor + disks + manifests). Conveys an appliance in one file.
- **XVA** (XenServer / Citrix): TAR archive with XML descriptors and disk images.
- **Vagrant BOX** (`.box`): TAR/ZIP bundle containing:
  - A metadata.json (provider, format)
  - One or more disk images (could be VMDK, VDI, QCOW2, etc, provider-dependent)
  - Provider-specific settings (VirtualBox .vbox, libvirt domain XML, etc).
- **Parallels `.PVM`**: Actually a directory bundle (package) containing .hdd disks, config, possibly snapshots.
- VMware “**VM directory**”: Not a single file, but a collection (.vmx, .vmdk, .nvram, logs). Sometimes informally zipped for distribution.
- **LXD/LXC** images: Rootfs tarballs plus metadata (not block-level disk; they are container/appliance but at system level).
- **Windows WIM/ESD** (for OS deployment): File-based imaging for OS installation rather than VM disk runtime.

---

## Cloud provider image abstractions

> (Not pure formats; they are higher-level constructs referencing underlying snapshots or objects.)

- **AMI** (Amazon Machine Image):
  - EBS-backed: References one (or more) EBS snapshot(s) (which themselves store raw blocks).
  - Instance-store (deprecated pattern): S3 bundle (historically a manifest + parts, often raw).
  - Older artifacts: AKI (kernel), ARI (ramdisk) in paravirtual era.
- **Azure Managed Image** / Shared Image Gallery:
  - Ultimately relies on a VHD (page blob) as the disk format. Upload is usually a fixed-size VHD.
- **GCE** (Google Compute Engine) Image:
  - Under the hood: A tarball with disk.raw plus metadata or direct import of a RAW / QCOW2 / VMDK / VHD converted into a persistent disk snapshot.
- OpenStack Glance Image:
  - Accepts multiple formats: raw, qcow2, vhd, vhdx, vmdk, vdi, iso, ami/ari/aki (legacy). Glance tracks disk_format and container_format (bare, ovf, docker, etc).
- IBM Cloud, Oracle Cloud Infrastructure:
  - Similar: You upload or reference QCOW2 / VMDK / RAW and it becomes a platform image ID.
- Alibaba Cloud ECS:
  - Imports RAW / QCOW2 / VHD; presents an image ID abstraction.

---

## Hypervisor / VM configuration & snapshot metadata

> (not disk images themselves, but part of the “image” ecosystem)

- VMware: .vmx (config), .nvram (virtual firmware vars), .vmsd (snapshot metadata), .vmsn (snapshot state, includes memory), .vmss (suspend state).
- VirtualBox: .vbox (XML), .vbox-prev, Logs.
- Hyper-V: .xml config (older), now stored internally in WMI/registry; .vmcx/.vmrs (newer config/runtime state), .bin (VM memory in checkpoints).
- KVM/libvirt: Domain XML definitions, plus separate disk images.
- Parallels: Config.pvs inside .pvm bundle.
- Checkpoint/memory state files: Not disk formats; ephemeral runtime or snapshot state.
- NVRAM / EFI variable stores: For UEFI-based guests (.nvram, .fd, etc).

---

## Backend block/image stores (infrastructure-level “images”)

> These are not files you pass around easily, but they can serve as VM roots:

- Ceph RBD volumes (block objects) used directly by KVM/libvirt as disks.
- LVM logical volumes or ZFS zvols (raw block devices).
- Sheepdog, Gluster-backed volumes for QEMU.
- iSCSI / Fibre Channel LUNs presented as raw disks to hypervisors.
- NVMe namespaces / storage arrays snapshots (vendor-specific).
- These lack a portable “file” format but conceptually are VM images.

---

## Deprecated / niche / legacy formats

- QED (QEMU Enhanced Disk) – abandoned; use QCOW2.
- Cloop (Compressed Loopback) – older Linux compressed block device used occasionally for live CDs.
- VPC (Virtual PC) – successor/sharing lineage with VHD; mostly replaced by VHD/VHDX.
- AMI/ARI/AKI separate kernel/ramdisk artifacts (legacy in modern AWS).
- VFloppy / .flp images (raw 1.44MB/2.88MB floppy images).
- RDI / RDIMG vendor-specific appliance packages (rare).
- XVA (still used, but niche outside XenServer).

---

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

Let me know if you’d like:

- A comparison matrix (features vs formats)
- Conversion command examples
- Best practices for building “golden” images across multiple clouds/hypervisors
- Snapshot/backup strategy recommendations per format

Just tell me what angle you want to go deeper on.
