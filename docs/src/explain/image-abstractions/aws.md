---
title: AWS AMI
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# AWS Image Abstractions

## AMI (Amazon Machine Image)

- AWS “AMI” is an image abstraction (an identifier + metadata) that references one or more underlying snapshots (normally EBS).
- EBS-backed AMI: Links to EBS volume snapshot(s); launch creates volumes from those snapshots.
- (Legacy) Instance-store AMI: Older pattern using S3 bundle manifest + parts; largely obsolete in modern workflows.
- An AMI also records virtualization type (hvm vs paravirtual), architecture, root device name, block device mappings, permissions (public, private, shared), and optional launch permissions.
- AMI is not a disk file format; it is an AWS registry object pointing to storage artifacts plus configuration.

## Legacy Paravirtual Identifiers (AKI / ARI) [Deprecated]

- AKI: Amazon Kernel Image ID (paravirtual Xen kernel) – superseded by HVM guests using their own kernel/EFI.
- ARI: Amazon Ramdisk Image ID (initrd) – paired with AKI in old paravirtual model.
- Modern HVM AMIs embed kernel/initrd inside the root filesystem; AKI/ARI fields are unused for new images.
- When converting very old paravirtual images, you may encounter these IDs; best practice is to rebuild as HVM.

## Root Device & Snapshot Model

- Root device type “ebs”: Each block device mapping points to an EBS snapshot (including the root volume).
- Root device type “instance-store”: Ephemeral NVMe/SATA storage on the host; root content delivered from S3 bundle at launch (rare today).
- Snapshots are incremental (EBS), enabling fast AMI copy and sharing operations.

## Import / Export Source Formats

- Supported import sources (via VM Import/Export): RAW, VMDK, VHD, VHDX, OVA (streamOptimized VMDK), sometimes QCOW2 (after conversion).
- Import pipeline converts your uploaded artifact (placed in S3) into one or more EBS snapshots then creates an AMI.
- Export (from EBS-backed AMI) can produce VMDK, VHD, VHDX, or RAW depending on chosen target.

## Image Lifecycle Operations

- Register: Create AMI from snapshot(s) or instance (CreateImage).
- Deregister: Removes AMI metadata; underlying snapshots remain unless deleted.
- Copy: Region-to-region duplication (creates new snapshots in target region).
- Share / Make Public: Adjust launch permissions; snapshots must also be shareable for full usability.
- Devirtualize / Rebake best practice: Regularly rebuild AMIs to pick up patches instead of snapshot layering indefinitely.

## Encryption & Compliance

- EBS-backed AMI snapshots can be encrypted (KMS); resulting launched volumes inherit encryption.
- Permissions interplay: To launch an encrypted shared AMI, target account must have KMS key access.
- AMI ID alone cannot convey encryption state of all block devices; inspect each block mapping.

## Versioning Strategy (Recommended)

- Embed semantic version or date stamp in AMI name (e.g. app-base-2024-11-07) and tags.
- Tag with: os_release, build_commit, hardening_profile, virtualization=hvm, root_size_gib.
- Maintain a pruning policy to retire old AMIs after validation of replacements.

## Common Pitfalls

- Confusing AMI ID with a portable disk format: It is cloud-specific metadata.
- Copying encrypted AMIs across accounts without granting KMS key permissions.
- Retaining legacy paravirtual AMIs (AKI/ARI) impedes modern instance types and performance features (ENA, Nitro, NVMe).
- Forgetting to re-run sysprep/cloud-init cleanup before creating an AMI from a running instance.

## Migration Notes (AKI/ARI to Modern HVM)

- Strategy: Start a modern HVM base (official distro image), install apps/config, migrate data, build new AMI.
- Direct conversion of paravirtual root FS into HVM often fails (missing initramfs drivers, bootloader config).
- Validate kernel modules (NVMe, ENA) and cloud-init configuration before final snapshot.

## Summary

- AMI = AWS image abstraction (pointer + metadata), not a disk file.
- AKI/ARI = deprecated paravirtual kernel/ramdisk IDs; avoid in new builds.
- Underlying storage: EBS snapshots (incremental) or legacy S3 bundles.
- Portability requires exporting/converting to a real disk format (RAW/VMDK/etc).
