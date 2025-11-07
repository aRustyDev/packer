---
title: RDI
deprecated: true
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# RDI (Vendor-Specific Appliance Bundle)

RDI (sometimes seen as `RDIMG` or similar naming) refers to a vendor-specific virtual appliance packaging convention rather than a standardized, multi-hypervisor format like OVF/OVA. Public, broadly accepted specifications for RDI are scarce, and tooling support is typically confined to the originating vendor’s ecosystem.

## Status

- Niche / legacy: Not adopted as an open interchange standard.
- Superseded in most workflows by OVF/OVA or cloud-native image abstractions (e.g., AMI, Azure Managed Image).
- Treat as deprecated for general-purpose distribution.

## Characteristics (Generalized)

| Aspect             | RDI (generic/vendor)                     |
| ------------------ | ---------------------------------------- |
| Openness           | Proprietary / undocumented publicly      |
| Typical Contents   | VM config + one or more disk image files |
| Portability        | Low outside original vendor tooling      |
| Integrity Metadata | Vendor-defined (may include checksums)   |
| Multi-VM Support   | Unclear / vendor-dependent               |

Because implementations vary, assume an RDI archive/bundle encodes:

- A descriptor or manifest (proprietary format).
- One or more disk payloads (often raw, VMDK, or a custom container).
- Optional checksum or signature artifacts.

## Why It Faded

- Lack of formal, published specification limits third-party tooling.
- Industry convergence on OVF/OVA for cross-hypervisor portability.
- Cloud platforms provide higher-level image abstractions reducing need for bespoke appliance bundles.
- Operational friction: conversion requires reverse engineering or vendor tools.

## Migration Strategy

1. Extract available disk images (using vendor export tooling if required).
2. Convert disk(s) to a widely supported format (e.g., RAW or QCOW2):
   `qemu-img convert -O raw vendor-disk.vmdk disk.raw`
3. Repackage using OVF/OVA (generate a fresh OVF descriptor referencing converted disks).
4. For cloud use, import converted RAW/VMDK into target platform image service (e.g., AWS VM Import → AMI, Azure → VHD upload).
5. Document any lost configuration semantics (special device flags, licensing metadata) and reapply manually.

## Risks & Limitations

- Potential hidden licensing or activation metadata not preserved through conversion.
- Unknown virtual hardware assumptions (paravirtual drivers, specific controller models).
- Possible embedded credentials/scripts—treat extracted artifacts as untrusted.
- Sparse or absent checksum verification outside vendor environment.

## When You Might Still Encounter It

- Legacy archives in enterprise labs.
- Vendor-distributed virtual appliances predating a switch to OVF/OVA.
- Forensic / compliance investigations of historical deployment artifacts.

## Recommended Handling

- Do not adopt RDI for new distributions.
- Prioritize re-baking appliances into standard OVF/OVA or direct cloud images.
- Maintain an internal conversion playbook (steps + tooling versions) for reproducibility.
- Tag converted outputs with provenance (original RDI source, conversion date, tool commit).

## Summary

RDI is a legacy, vendor-bound appliance packaging convention with limited modern relevance. Treat it as deprecated; migrate any remaining artifacts to transparent, documented formats (OVF/OVA or cloud image services). Preserve originals only for audit/provenance—do not extend its usage in active pipelines.
