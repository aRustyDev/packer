---
title: OVF
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# OVF

- OVA vs OVF: OVA = TAR-wrapped OVF set. OVF = descriptor + separate disks.
- **OVF (Open Virtualization Format)**: An open, portable packaging standard composed primarily of an XML descriptor (`.ovf`) plus referenced artifact files (virtual disks, manifests, optional certificates). It describes a virtual system (or set of systems) in a hypervisor‑neutral way.

## What OVF Is (and Is Not)

- It IS: A hardware + deployment metadata descriptor for one or more virtual machines (VirtualSystems) or a VirtualSystemCollection.
- It IS NOT: A virtual disk file format itself (the disks remain VMDK, VHD, QCOW2, etc).
- It IS NOT: A runtime configuration state container (no running memory snapshot).
- It CAN: Include references to ISO images for installation media, multiple NIC definitions, CPU/memory settings, and product metadata.

## Typical File Set (Directory Form)

```
appliance.ovf        # Primary XML descriptor
disk0.vmdk           # First virtual disk (could be streamOptimized when exported from VMware)
disk1.vmdk           # Additional disk(s) if present
appliance.mf         # (Optional) Manifest with cryptographic hashes
appliance.cert       # (Optional) Signature / certificate
```

In “pure OVF” distribution these remain separate files (unlike OVA which tars them together).

## Core Sections of the OVF Descriptor

- References: Maps `ovf:File` and `ovf:DiskSection` entries to physical disk files.
- Envelope / VirtualSystem / VirtualSystemCollection: Defines one VM or a multi-VM service set.
- VirtualHardwareSection:
  - Lists virtual devices (CPU, memory, storage controllers, NICs, video).
  - Uses CIM (Common Information Model) class IDs / ResourceType codes.
- DiskSection: Logical disk declarations (capacity, format, parent relationships).
- NetworkSection: Declares logical networks (bridges for multi-VM appliances).
- ProductSection: Vendor/product metadata (version, URL, licensing info).
- AnnotationSection (optional): Human readable notes.
- EulaSection (optional): End-user license notice.

## Advantages

- Hypervisor neutrality (descriptor can be consumed by multiple platforms).
- Explicit hardware list simplifies validation (e.g. CPU count, NIC model).
- Supports multi-VM appliances (service topology).
- Manifest file enables integrity verification of all referenced content.
- Extensible via vendor namespaces for additional properties.

## Limitations / Caveats

- Real-world compatibility depends on how strictly consumers adhere to spec (some ignore advanced sections).
- Hardware abstraction gaps: Certain device models (e.g. paravirtual SCSI types) may not translate cleanly.
- Updating a disk file requires re-hashing and updating manifest.
- Not all hypervisors ingest every optional section (some ignore Product/Eula metadata).
- Conversion tooling may flatten/alter subtle device attributes (e.g., controller ordering).

## Common Use Cases

- Vendor distribution of virtual appliances across VMware, VirtualBox, and other environments.
- Template interchange between lab/build pipelines and multiple hypervisors.
- Multi-VM service packaging (web tier + DB tier) as a collection.
- Compliance: Including licensing and product metadata in a standardized descriptor.

## Creation Workflows

- VMware: Use `ovftool` to export directory layout instead of OVA.
  - Example: `ovftool vi://user@esxi-host/vmName ./export-dir/`
- VirtualBox: `VBoxManage export <vm> --ovf20 --output export-dir/appliance.ovf`
- Hand assembly: Craft `.ovf` XML referencing existing disk files (advanced / less common).

## Validation

- Schema check: Use tools (`ovftool`, VirtualBox importer) to lint descriptor.
- Manifest verification:
  - `sha256sum -c appliance.mf` (must run in same directory).
- Reference integrity: Ensure all `ovf:File` IDs map to existing disk paths and sizes match metadata.

## Conversion / Import

- OVF -> Target Hypervisor:
  - VMware: `ovftool appliance.ovf vi://esxi-host/`
  - VirtualBox: `VBoxManage import appliance.ovf`
  - KVM/libvirt: Often indirect—convert disk formats with `qemu-img`, then manually define domain XML (no native full OVF import in vanilla libvirt).
- Disk format adaptation:
  - If consumer cannot use VMDK directly: `qemu-img convert -p -O qcow2 disk0.vmdk disk0.qcow2`
  - Update descriptor only if disk filename or capacity metadata changes.

## Editing An Existing OVF (Best Practices)

1. Extract hardware requirements (RAM, CPU) you intend to alter.
2. Modify only relevant VirtualHardwareSection items.
3. Recalculate manifest digests (`sha256sum *.ovf *.vmdk > appliance.mf`) if present.
4. Keep original descriptor backups for diff review.
5. Avoid introducing hypervisor-specific extensions unless necessary (reduces portability).

## Security & Integrity

- Manifest digests (SHA256 preferable) defend against tampering.
- Signed certificate file adds provenance (not universally validated).
- Always inspect ProductSection / EulaSection to catch unexpected licensing constraints.
- Treat unknown vendor disks as untrusted: scan in an isolated environment before production.

## Multi-VM Collections

- VirtualSystemCollection aggregates multiple VirtualSystem elements.
- NetworkSection defines logical networks; individual VMs attach NICs referencing these.
- Consumers not supporting multi-VM may import only the first VirtualSystem silently—validate behavior.

## Choosing OVF vs OVA

| Scenario                                           | Prefer OVF | Prefer OVA |
| -------------------------------------------------- | ---------- | ---------- |
| Iterative development & frequent tweaks            | Yes        | No         |
| One-shot public distribution                       | Maybe      | Yes        |
| Large multi-disk appliance (change one disk often) | Yes        | No         |
| Need easy email/object-store transport             | No         | Yes        |
| Automated CI signing & manifest regen              | Either     | Either     |

## Common Pitfalls

- Forgetting to update manifest after disk changes—imports fail or warn.
- Using uncommon or proprietary virtual device types reducing portability.
- Oversizing logical disk capacity beyond consumer host free space.
- Assuming conversion preserves special controllers (e.g., PVSCSI) automatically.

## Best Practices Summary

- Keep descriptor minimal: only declare devices actually needed.
- Use widely supported disk formats (streamOptimized VMDK, or RAW) for broad compatibility.
- Always regenerate manifest after any content change.
- Version your appliance (e.g., add `productVersion` attribute in ProductSection and encode version in directory or filename).
- Maintain a changelog external to OVF for operational clarity.

## Lifecycle Management

- Versioned directories: `myapp-1.3.0/` containing OVF + disks.
- Deprecate older versions via documentation & tagging; avoid in-place edits once published.
- Automate export + validation in CI (lint descriptor, verify digests, produce SBOM if applicable).

## Summary

- OVF provides a flexible, portable way to describe virtual appliances separate from raw disk formats.
- It enhances integrity (manifests), metadata richness (Product/Eula), and multi-VM packaging.
- OVF directory form is better for iterative workflows; OVA (tarred) better for distribution convenience.
- Success depends on disciplined manifest management, conservative device choices, and consistent versioning.
