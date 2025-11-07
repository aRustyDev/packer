---
title: VHD
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# VHD (Virtual Hard Disk)

`VHD` is the original Microsoft / Connectix virtual disk image format. It remains widely supported across hypervisors and tooling, though it has largely been superseded by `VHDX` for new Hyper‑V workloads. Azure still requires fixed (not dynamically expanding) VHD images for custom image uploads, so VHD retains practical relevance in cloud import/export pipelines.

## Core Characteristics

- File-based virtual disk container.
- Supports three structural variants:
  - Fixed: Fully preallocated to declared size (best for Azure compatibility).
  - Dynamic: Starts small; grows as blocks are written (metadata overhead, fragmentation risk).
  - Differencing: Parent/child chain (copy‑on‑write) for snapshots or layering.
- Maximum size: 2 TB (hard upper limit; one reason for migration to VHDX).
- Block allocation table and footer define disk geometry and features.
- End-of-file (footer) contains signature (conectix), timestamp, disk type, checksum.

## VHD vs VHDX (Quick Contrast)

| Aspect              | VHD                            | VHDX                                        |
| ------------------- | ------------------------------ | ------------------------------------------- |
| Max size            | 2 TB                           | 64 TB                                       |
| Resiliency          | No journaling                  | Metadata journaling reduces corruption risk |
| Block alignment     | 512-byte logical sectors       | Supports 4K logical sectors                 |
| Performance on 4K   | Potential misalignment issues  | Better for modern storage                   |
| Feature extensions  | Limited                        | Extensible headers                          |
| Trim/Unmap handling | Basic / host-dependent         | Improved semantics                          |
| Use in new Hyper‑V  | Legacy / compatibility         | Recommended default                         |
| Azure requirement   | Requires fixed VHD for uploads | Not accepted directly                       |

## Disk Types (Descriptors)

| Type (Header) | Purpose                              |
| ------------- | ------------------------------------ |
| Fixed         | Single preallocated extent           |
| Dynamic       | Sparse; block allocation table grows |
| Differencing  | References a parent (chain layering) |

Differencing disks store changed blocks in the child; reads fall back to parent for unchanged regions.

## Common Use Cases Today

- Azure custom image import (fixed VHD required).
- Legacy Hyper‑V environments (pre‑Windows Server 2012).
- Interoperability workflows needing broad tooling support (many convert utilities accept VHD).
- Transitional artifacts in image conversion pipelines (RAW ↔ VHD ↔ VHDX ↔ QCOW2).

## Creation & Conversion (Representative Commands)

Using qemu-img:

- Create fixed (preallocated) VHD suitable for Azure:
  qemu-img create -f vpc -o subformat=fixed disk.vhd 40G

- Convert RAW to fixed VHD:
  qemu-img convert -p -O vpc -o subformat=fixed disk.raw disk.vhd

(Note: qemu-img uses format name `vpc` for VHD; `vhdx` for VHDX.)

Verify:

qemu-img info disk.vhd

## Performance Considerations

| Factor             | Impact / Guidance                                                    |
| ------------------ | -------------------------------------------------------------------- |
| Fixed vs Dynamic   | Fixed avoids expansion overhead; better for predictable performance  |
| Fragmentation      | Dynamic disks fragment over time; periodic conversion can defragment |
| Differencing chain | Deep chains degrade I/O latency; keep shallow and consolidate early  |
| 4K sector storage  | VHD limited to 512 logical sectors → potential RMW penalty           |
| Preallocation      | Fixed ensures host allocation upfront; avoids runtime surprises      |

If long-lived, dynamically expanding VHD grows significantly, consider flattening:

qemu-img convert -p -O vpc -o subformat=fixed dynamic.vhd flattened.vhd

## Snapshot / Layering Strategy (Differencing Disks)

- Differencing VHDs (child) reference a parent’s unique ID and timestamp.
- Chain corruption risk rises with manual moves/renames; always use Hyper‑V or supported tooling.
- For long-term retention or distribution, flatten differencing chains into a single fixed VHD.

Flatten example:

qemu-img convert -p -O vpc -o subformat=fixed child.vhd merged.vhd

## Integrity & Corruption Risks

- No journaling → metadata vulnerable to host crashes during expansion.
- Rely on external checksums (SHA256) for artifact integrity:
  sha256sum disk.vhd > disk.vhd.sha256
- Avoid abrupt host power loss during dynamic growth operations.

## Azure-Specific Notes

- Requires fixed-size VHD aligned to 1 MiB boundaries internally (qemu-img fixed creation is acceptable).
- Recommended workflow:
  1. Build image in a feature-rich format (QCOW2 / VHDX).
  2. Convert to fixed VHD.
  3. Upload to Azure Blob (page blob) with proper tooling (Azure CLI / AzCopy).
  4. Create managed image or shared image gallery version referencing the uploaded VHD.
- Ensure OS provisioning agents (Azure Linux Agent / Windows Sysprep) are prepared before conversion.

## When to Migrate to VHDX

| Trigger                                    | Rationale                                   |
| ------------------------------------------ | ------------------------------------------- |
| Disk > 2 TB needed                         | VHDX supports up to 64 TB                   |
| Frequent power events / crash exposure     | VHDX journaling reduces metadata corruption |
| Need 4K logical sector optimization        | VHDX supports native large sector mapping   |
| Advanced features (e.g., trim, resiliency) | Better support in VHDX                      |

If compatibility with older tooling or Azure fixed import is not required, prefer VHDX for new Hyper‑V workloads.

## Recommended Best Practices

- Use VHD only when required (Azure import, legacy compatibility).
- Prefer fixed VHD for reliability, predictable performance, and cloud acceptance.
- Keep differencing chains short; flatten before distribution.
- Maintain a canonical RAW or VHDX and derive VHD as an output artifact.
- Include metadata tags (build date, OS version) externally (tags, manifest) since VHD lacks rich extensibility.

## Common Pitfalls

| Pitfall                        | Impact                                       | Mitigation                                    |
| ------------------------------ | -------------------------------------------- | --------------------------------------------- |
| Uploading dynamic VHD to Azure | Import failure or performance issues         | Always convert to fixed before upload         |
| Oversized expectations (>2 TB) | Hard limit prevents scaling                  | Migrate to VHDX or split design               |
| Deep differencing chains       | I/O latency, consolidation complexity        | Restrict chain depth; consolidate early       |
| Ignoring 4K sector alignment   | Suboptimal performance on modern storage     | Migrate to VHDX or ensure proper guest tuning |
| Manual editing of headers      | Corruption / invalid parent-child references | Use supported tools only                      |

## Migration Path (Example)

1. Start with source QCOW2: source.qcow2
2. Convert to VHDX for modern Hyper‑V: qemu-img convert -p -O vhdx source.qcow2 base.vhdx
3. Prepare Azure artifact: qemu-img convert -p -O vpc -o subformat=fixed base.vhdx azure-fixed.vhd
4. Upload azure-fixed.vhd to Azure storage and register image.

## Summary

VHD is a legacy yet still operationally important virtual disk format, primarily retained for compatibility (notably Azure fixed image imports and older Hyper‑V environments). It lacks the scalability and resiliency enhancements found in VHDX. Use fixed VHD for required interoperability; otherwise adopt VHDX or RAW as a base and treat VHD as a derived distribution artifact. Keep chains shallow, verify integrity with external hashing, and plan migrations off VHD where growth, resiliency, or large sector optimization demands arise.
