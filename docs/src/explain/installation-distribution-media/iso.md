---
title: ISO
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# ISO

ISO images are byte-for-byte representations of (typically) optical disc file systems used for OS installation, live environments, rescue media, firmware updates, or content distribution. They are not the same as virtual machine disk images (which represent an installed system’s block device). Instead, an ISO is an installation or boot medium.

## What It Is (and Is Not)

- It IS: A bootable (usually) read-only filesystem image—commonly ISO9660 plus extensions (Joliet, Rock Ridge) and often hybridized with El Torito boot catalog, GPT/MBR for USB boot, and sometimes EFI System Partition (ESP) embedding.
- It IS NOT: A persistent VM disk with mutable state; you don’t snapshot an ISO (you rebuild it).
- It CAN: Contain boot loaders (BIOS El Torito, EFI bootx64.efi), kernel/initrd, package repositories, preseed/kickstart/autoinstall configs, live OS root (SquashFS).
- It CANNOT (by itself): Store runtime changes across reboots (unless overlays are configured by the live system in RAM or persistence partitions outside the ISO).

## Core Components

Typical modern Linux distribution ISO may include:

- ISO9660 filesystem root
- El Torito boot catalog (points to boot image: isolinux.bin, grub, or EFI image)
- EFI System Partition image (FAT) for UEFI boot
- Kernel (`vmlinuz`) and initrd
- Compressed root (e.g. `live/filesystem.squashfs`)
- Metadata (package manifests, checksums)
- Automated install configs (Kickstart, Preseed, Autoinstall YAML, cloud-init seed)

## Boot Mechanisms

1. BIOS (Legacy):
   - El Torito catalog entry referencing a boot image (often ISOLINUX or GRUB BIOS stage).
2. UEFI:
   - Embedded EFI System Partition (ESP) as an El Torito EFI entry OR hybrid GPT/MBR layout allowing direct mount.
3. Hybrid ISO:
   - Uses isohybrid tooling to make the same image directly bootable from USB (adds MBR + sometimes GPT structures).
4. Secure Boot:
   - Signed EFI binaries (shim + grub + kernel) included; validation occurs before kernel load.

## Common Use Cases

- Initial OS installation (attach ISO to a VM or bare metal via remote media).
- Live/rescue environment for diagnostics.
- Automated provisioning (cloud-init seed plus autoinstall config).
- Firmware / appliance updates (vendors still distribute ISO updaters).
- Air-gapped package distribution.

## Creation Tooling (Examples)

- `xorriso`, `mkisofs`, `genisoimage`: Construct the ISO filesystem and El Torito structures.
- `isohybrid` (from syslinux): Make ISO USB-bootable without modification.
- `implantisomd5`: Embed checksum for installer verification.
- `oscdimg` (Windows) for building Windows installation media.
- Specialized distros use build frameworks (e.g., Fedora `lorax`, Debian `debian-cd`, Ubuntu `live-build`).

## Minimal Linux Example (Conceptual)

1. Prepare root staging directory (`staging/`) with kernel, initrd, isolinux or grub config, and (optional) SquashFS root.
2. Create SquashFS of rootfs: `mksquashfs rootfs/ staging/live/filesystem.squashfs -comp xz`
3. Produce ISO:
   ```
   xorriso -as mkisofs \
     -iso-level 3 -full-iso9660-filenames \
     -volid "MY_LIVE" \
     -eltorito-boot isolinux/isolinux.bin \
     -eltorito-catalog isolinux/boot.cat \
     -no-emul-boot -boot-load-size 4 -boot-info-table \
     -eltorito-alt-boot \
     -e EFI/boot/efiboot.img -no-emul-boot \
     -output my-live.iso staging
   ```
4. Optional isohybrid: `isohybrid --uefi my-live.iso`

## Verification & Integrity

- Hashing: `sha256sum my.iso` (publish checksum alongside).
- GPG signature: `gpg --detach-sign --armor my.iso`
- Embedded MD5 (some installers): `checkisomd5 my.iso` (distro-specific).
- Loop mount for inspection: `mount -o loop my.iso /mnt/iso`

## Limitations vs VM Disk Images

| Aspect          | ISO                                | Virtual Disk (RAW/QCOW2/VMDK)      |
| --------------- | ---------------------------------- | ---------------------------------- |
| Mutability      | Read-only                          | Read/write                         |
| Purpose         | Installation / live boot           | Persistent OS runtime              |
| Snapshots       | Rebuild only                       | Supported (format-dependent)       |
| State retention | External (overlays, persistence)   | Intrinsic                          |
| Conversion      | Not convertible to a disk runstate | Convertable between disk formats   |
| Cloud import    | Rarely accepted directly           | Standard (RAW/VMDK/VHD/VHDX/QCOW2) |

## When To Use an ISO

Use an ISO when you:

- Need a clean, reproducible installer or live environment.
- Want to distribute a vendor appliance _installer_ rather than a ready-to-run image.
- Are performing PXE alternative (mounting ISO virtually through IPMI / BMC).
- Need to embed preseed/auto-install logic that runs before OS is laid down.

Choose a disk image format when you:

- Want an already-installed OS template (faster provisioning).
- Need incremental updates or snapshot strategies.

## Automation & Customization

- Kickstart / Preseed / Autoinstall: Insert config into ISO (e.g., editing `grub.cfg` or `isolinux.cfg` to point to answer file).
- cloud-init seed injection approach:
  - Boot installer ISO + attach separate seed (config-drive) ISO.
  - Or rebuild installer ISO embedding `user-data`/`meta-data`.
- Windows:
  - Use `oscdimg` with an extracted WIM; slipstream drivers (DISM) before ISO creation.

## Performance Considerations

- Live systems rely on decompression (SquashFS + XZ/LZ4) affecting boot speed vs installed disk.
- Larger compression ratios reduce size but increase CPU overhead.
- Hybrid ISO layout can introduce slight alignment inefficiencies for USB boot but negligible for typical use.

## Security Considerations

- Validate upstream cryptographic signatures (distribution-supplied GPG keys).
- Treat third-party ISOs as untrusted: test in isolated VM network first.
- Ensure no embedded default credentials or unintended automation scripts before distributing customized ISOs.

## Common Pitfalls

- Forgetting to regenerate boot catalog after altering boot files.
- Misconfigured EFI boot image leading to BIOS-only or UEFI-only boot failures.
- Using non-hybrid ISO when expecting direct USB dd deployment.
- Embedding outdated or mismatched kernel/initrd relative to modules in SquashFS.

## Best Practices

- Always publish SHA256 (and optionally GPG signatures) for distributed ISOs.
- Maintain a build manifest (source package versions, build timestamp, git commit).
- Keep customization scripts idempotent and version-controlled.
- Prefer deterministic compression settings for reproducible builds.
- Test both BIOS and UEFI boot paths in CI if advertising dual support.

## Rebuilding vs Patching

- Rebuilding ensures a fresh, cryptographically consistent artifact.
- Avoid “mount ISO, edit, re-pack” hacks—can break signatures and boot structures; script the full build instead.

## Summary

- ISO images are distribution and installation artifacts, not runtime VM disks.
- They encapsulate boot loaders, kernels, installers, and optional live root filesystems.
- For fast provisioning in virtualized environments, pre-installed disk images are usually superior; ISOs remain essential for installation workflows, recovery, and standardized distribution.
- Treat ISO creation as a reproducible, automated build pipeline with integrity verification.
