---
title: HDD
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# HDD (Parallels Virtual Disk)

`HDD` is the virtual disk image format used by Parallels Desktop (macOS) and Parallels Server products. It typically lives inside a `.pvm` (Parallels VM bundle) directory alongside configuration, NVRAM, and snapshot files. While functional for Parallels workflows, it is not broadly adopted outside that ecosystem; for multi-hypervisor portability you usually convert the `.hdd` contents to a common format (RAW, QCOW2, VMDK, VHDX).

## What It Is (and Is Not)

- IS: A container (often a directory or a single file depending on version) holding block allocation structures + guest data.
- IS: Integrated with Parallels snapshot / differencing mechanisms (separate delta layers).
- IS NOT: A widely supported interchange format—other hypervisors do not ingest `.hdd` directly.
- IS NOT: A feature-super-set beyond mainstream formats; serves mostly Parallels runtime needs.

## Typical Layout Inside a `.pvm` Bundle

```
MyVM.pvm/
  config.pvs          # Parallels VM configuration
  <diskname>.hdd/     # Disk bundle directory (newer versions) OR <diskname>.hdd (single file)
    DiskDescriptor.xml (descriptor metadata)
    DiskImage           (base extent or block store segments)
    Snapshots/          (snapshot delta structures)
    ...
  <vm-name>.mem        # (Optional) suspended memory state
  <vm-name>.sav        # (Optional) saved state
  logs/                # Runtime logs
  floppy.fdd           # (Optional) virtual floppy image
```

Older versions sometimes used a monolithic `.hdd` file; newer ones prefer a directory with descriptor + extent segments.

## Core Characteristics

| Feature           | HDD (Parallels)                                         |
| ----------------- | ------------------------------------------------------- |
| Sparse allocation | Yes (dynamic growth supported)                          |
| Snapshots         | Yes (internal layering / separate delta components)     |
| Compression       | Limited / internal (not common for distribution)        |
| Encryption        | Provided at product level (not standardized externally) |
| Max size          | Large (host filesystem / product constraints)           |
| Portability       | Low (needs conversion)                                  |
| Descriptor format | XML manifest (DiskDescriptor.xml)                       |

## Snapshot / Delta Model

- Base (primary) disk stores original guest blocks.
- Each snapshot creates a delta layer referencing unchanged blocks in parents.
- Excessive snapshot depth causes read amplification and performance degradation similar to long VMDK or QCOW2 chains.
- Consolidation (merging) is done via Parallels management tools; manual tampering risks data loss.

## Common Use Cases

| Scenario                               | Suitability |
| -------------------------------------- | ----------- |
| Local macOS virtualization (dev/test)  | High        |
| Running Windows/Linux workloads on Mac | High        |
| Cross-hypervisor distribution          | Low         |
| Cloud import pipelines                 | Low         |
| Forensics of Parallels VMs             | Moderate    |

## Conversion Strategy

To use a Parallels VM disk in other hypervisors:

1. Shut down / remove snapshots (flatten) inside Parallels.
2. Locate the `.hdd` directory (or monolithic file).
3. Export / convert using Parallels tools (if available) OR extract raw blocks:
   - Parallels Desktop provides an "Convert to other format" wizard (version-dependent).
4. If only block extents are available:
   - Use `qemu-img convert -O raw source.hdd target.raw` (requires a build of qemu-img supporting Parallels; some builds include `parallels` driver).
   - Then convert to desired format:
     ```
     qemu-img convert -p -O qcow2 target.raw target.qcow2
     qemu-img convert -p -O vmdk -o subformat=streamOptimized target.raw target.vmdk
     ```
5. Validate by booting a test VM in target hypervisor.

Note: If qemu-img lists `parallels` in `qemu-img --help`, you can directly do:

```
qemu-img convert -p -O raw -f parallels disk.hdd disk.raw
```

## Performance Considerations

| Factor              | Impact / Guidance                                                         |
| ------------------- | ------------------------------------------------------------------------- |
| Snapshot depth      | Keep shallow; consolidate before heavy use.                               |
| Host storage (APFS) | APFS snapshots + HDD snapshots can compound fragmentation.                |
| Dynamic growth      | Periodic compaction / clone recommended for sustained performance.        |
| Large sequential IO | Flatten snapshots; consider converting to RAW for heavy processing tasks. |

## Space Reclamation

- Guest TRIM/discard may be partially supported depending on virtual controller configuration.
- Compaction requires:
  1. Zero / discard free space inside guest (e.g. `fstrim -av` or write/delete a zero file).
  2. Use Parallels GUI/CLI compact function (when available) to reclaim unallocated blocks.

## Integrity & Backup

- Backup entire `.pvm` bundle to ensure consistency (disk + config + snapshot metadata).
- For snapshot-heavy VMs, prefer a consolidation step before a long-term archival backup.
- Use external hashing for the final exported artifact:
  ```
  shasum -a 256 disk.raw > disk.raw.sha256
  ```

## When to Avoid HDD

| Requirement                                       | Prefer Instead            |
| ------------------------------------------------- | ------------------------- |
| Multi-cloud image pipeline                        | RAW / QCOW2 / VMDK        |
| Native KVM/libvirt environment                    | QCOW2                     |
| VMware ecosystem integration                      | VMDK                      |
| Large-scale automation / Packer builds            | Produce canonical RAW     |
| Advanced snapshot orchestration outside Parallels | QCOW2 / VMDK delta chains |

## Security Considerations

- Rely on Parallels product-level encryption rather than assuming HDD format secures data.
- For distribution outside trusted environment, convert to a mainstream format and apply standard encryption (LUKS, BitLocker).
- Audit for embedded credentials or provisioning artifacts before distributing a converted image.

## Migration Path (Parallels → KVM Example)

```
# Ensure VM is powered off and snapshots consolidated
# Convert HDD to raw (if supported)
qemu-img convert -p -O raw -f parallels MyDisk.hdd mydisk.raw

# Convert raw to qcow2 for KVM
qemu-img convert -p -O qcow2 mydisk.raw mydisk.qcow2

# Define libvirt domain referencing mydisk.qcow2
```

## Common Pitfalls

| Pitfall                                | Consequence                               | Mitigation                      |
| -------------------------------------- | ----------------------------------------- | ------------------------------- |
| Retaining deep snapshot chains         | Performance degradation, merge complexity | Consolidate early               |
| Copying partial `.hdd` contents only   | Broken VM (missing metadata)              | Copy entire `.pvm` bundle       |
| Assuming direct import in other HVs    | Import failure                            | Convert before migration        |
| Ignoring guest trimming before compact | Bloated disk size                         | Run fstrim / zeroing pass first |
| Manual editing of DiskDescriptor.xml   | Corruption / chain break                  | Use official tools only         |

## Best Practices

- Keep snapshot depth minimal (treat snapshots as temporary).
- Flatten and convert before long-term archival or cross-platform sharing.
- Maintain a canonical golden RAW image outside Parallels for multi-hypervisor pipelines.
- Version/tag builds externally (name + checksum manifest).
- Periodically validate conversions by automated boot tests in target hypervisors.

## Summary

The Parallels `HDD` format is a virtualization-specific disk container optimized for Parallels Desktop workflows on macOS. Its limited portability makes it a poor choice for multi-hypervisor or cloud distribution; convert to RAW, QCOW2, or VMDK for broader compatibility. Manage snapshot depth carefully, compact after freeing guest space, and treat the entire `.pvm` bundle as the atomic backup unit. For modern, portable image pipelines, use HDD only as an internal build artifact—export standardized formats for external consumption.
