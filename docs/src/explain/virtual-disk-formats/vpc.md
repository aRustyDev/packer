---
title: VPC
deprecated: true
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# VPC

- VPC (Virtual PC) – successor/sharing lineage with VHD; mostly replaced by VHD/VHDX.

## Status

Deprecated. Retained only for historical compatibility; modern Hyper‑V and Azure workflows expect VHDX or (for Azure uploads) fixed VHD.

## Key Points

- Max size limitation inherited from original implementation (like VHD 2 TB limit).
- Lacks resiliency features (no journaling) present in VHDX.
- Limited sector alignment flexibility compared to VHDX.
- Should not be used for new image creation—convert instead.

## Migration

1. Identify any remaining `.vpc`/`vpc` format artifacts (sometimes reported by `qemu-img info` as `vpc`).
2. Convert to VHDX (preferred) or RAW:
   - `qemu-img convert -p -O vhdx legacy.vpc modern.vhdx`
   - `qemu-img convert -p -O raw legacy.vpc disk.raw`
3. Validate boot and workload.
4. Decommission original VPC image after backup retention window.

## When You Still Encounter It

- Old lab archives or vendor images predating widespread VHD adoption.
- Documentation/examples from early virtualization eras.
- Forensic analysis of legacy virtual environments.

## Recommendation

Treat VPC as a legacy artifact. Standardize on:

- VHDX for Hyper‑V feature use (large disks, resiliency).
- RAW for canonical cross-hypervisor conversion sources.
- VHD (fixed) only when required by Azure import constraints.

## Summary

VPC is an obsolete virtual disk format historically aligned with early Virtual PC workflows and superseded by VHD/VHDX. Migrate any remaining instances to maintained formats; avoid generating new VPC images in contemporary pipelines.
