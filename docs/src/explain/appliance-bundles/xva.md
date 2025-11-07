---
title: XVA
deprecated: true
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# XVA

- **XVA (Xen Virtual Appliance)** is a XenServer / Citrix XenCenter appliance bundle format.
- Structurally it is a single TAR archive containing:
  - An XML manifest (metadata: VM configuration, virtual hardware settings).
  - One or more disk image files (often raw stream segments).
  - Supplemental files (e.g. checksums) depending on XenServer version.

## Status

- Considered niche/legacy outside XenServer ecosystems.
- Other ecosystems prefer OVF/OVA for portability.
- Many modern workflows export to OVF/OVA instead of XVA for broader compatibility.

## Typical Use Cases (Historical)

- Exporting a VM from XenCenter to move between XenServer hosts.
- Archiving a VM configuration + disks in one distributable artifact.
- Providing vendor virtual appliances targeted specifically at XenServer.

## Limitations

- Limited tooling support outside XenServer/Citrix stack.
- Conversion usually requires:
  1. Untar XVA.
  2. Extract disk streams.
  3. Reassemble / convert disks (e.g. to RAW or VMDK using `qemu-img`).
  4. Create a new descriptor (OVF or cloud-specific import recipe).
- Lacks the broader ecosystem validation and manifest extensions present in OVF.

## Conversion Notes (Stub)

- To migrate XVA -> OVF/OVA:
  - Extract disk(s): `tar -xf vm.xva`
  - Identify disk payload files (commonly large numbered segments).
  - Concatenate / convert to a single RAW, then to target (QCOW2/VMDK) as needed.
  - Generate OVF descriptor manually or via a script.

## Summary

- XVA = XenServer-specific appliance archive (TAR + XML + disk data).
- Niche compared to OVF/OVA; treat as deprecated for general multi-hypervisor distribution.
- Prefer producing OVF/OVA when portability beyond XenServer is required.
