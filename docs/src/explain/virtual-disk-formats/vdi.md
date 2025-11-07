---
title: VDI
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# VDI (VirtualBox Disk Image)

`VDI` is the native virtual disk file format used by Oracle VirtualBox. It supports sparse (dynamic) and fixed allocation, integrates with VirtualBox’s snapshot mechanism, and is broadly convertible to and from other common formats (RAW, VMDK, VHD(X), QCOW2) via `VBoxManage` or `qemu-img`.

## Core Characteristics

| Aspect           | Details                                                                  |
| ---------------- | ------------------------------------------------------------------------ |
| Container type   | Single file holding both metadata and data blocks                        |
| Allocation modes | Dynamic (default) or Fixed                                               |
| Maximum size     | Up to 2 TB (practical); larger possible in newer versions (theoretical)  |
| Snapshot support | External to file (VirtualBox manages differencing VDIs in snapshot tree) |
| Compression      | Not built-in (use external filesystem or convert)                        |
| Encryption       | Managed at VM level (VirtualBox encryption), not intrinsic to VDI        |
| Portability      | High (convertible)                                                       |
| Sparse growth    | Block-based on demand allocation                                         |

## File Structure (Conceptual)

1. Header (magic, version, UUID, geometry, block size, allocation table offsets).
2. Block Allocation Map (indicates whether each logical block is allocated and the file offset).
3. Data Blocks (actual guest disk data; absent/unallocated blocks read as zero).
4. Optional metadata extensions (depending on VirtualBox version).

Unlike formats with internal snapshot metadata (QCOW2), VDI keeps snapshot layering outside the base image: each snapshot introduces a differencing VDI referencing its parent.

## Allocation Modes

| Mode    | Behavior                                                    | Use Case                              |
| ------- | ----------------------------------------------------------- | ------------------------------------- |
| Dynamic | File grows as guest writes to previously unallocated blocks | General purpose, space efficiency     |
| Fixed   | Full size allocated immediately (all blocks present)        | Predictable performance, benchmarking |

Create fixed disks when fragmentation or latency variability is a concern.

## Creation & Basic Operations

Create a dynamic VDI:

```
VBoxManage createhd --filename disk.vdi --size 40960 --format VDI
```

Create a fixed VDI:

```
VBoxManage createhd --filename disk-fixed.vdi --size 40960 --format VDI --variant Fixed
```

Show info:

```
VBoxManage showhdinfo disk.vdi
```

Resize (only for dynamic or when guest FS supports expansion):

```
VBoxManage modifymedium disk.vdi --resize 51200
```

(Then grow partition/filesystem inside guest.)

## Conversion Examples

Using `VBoxManage`:

```
VBoxManage clonehd disk.vdi disk.vmdk --format VMDK
VBoxManage clonehd disk.vdi disk.qcow2 --format QCOW
```

Using `qemu-img` (VDI is supported):

```
qemu-img convert -p -O raw disk.vdi disk.raw
qemu-img convert -p -O qcow2 disk.vdi disk.qcow2
qemu-img convert -p -O vmdk disk.vdi disk.vmdk
```

Going the other way:

```
qemu-img convert -p -O vdi source.qcow2 disk.vdi
```

## Snapshots (VirtualBox Model)

VirtualBox snapshots create differencing VDI files:

- Base disk: original VDI (read-only while snapshots exist).
- Snapshot delta: stores changed blocks; chaining occurs with multiple snapshots.

Pitfalls:

- Deep chains reduce performance (extra lookups).
- Deleting snapshots triggers merge/consolidation (I/O intensive).
- Recommended: Keep snapshot depth shallow (≤3), consolidate before heavy use or distribution.

To export a flattened disk:

1. Delete all snapshots (or clone current state).
2. `VBoxManage clonehd current-diff.vdi flattened.vdi --format VDI`

## Performance Considerations

| Factor                | Impact / Guidance                                                      |
| --------------------- | ---------------------------------------------------------------------- |
| Dynamic fragmentation | Can increase random I/O latency; periodic clone to fresh VDI mitigates |
| Block size (internal) | Fixed by format; not user tunable; rely on host FS alignment           |
| Host filesystem       | Use performant storage (SSD/NVMe) for heavy random workloads           |
| Snapshots             | Keep chain short; clone to flatten when performance degrades           |
| Fixed allocation      | Reduces fragmentation but consumes full capacity immediately           |

Defragment strategy:

- Clone to a new VDI (`VBoxManage clonehd`) which writes blocks contiguously.
- Or convert via `qemu-img` and back.

## Space Reclamation

Guest TRIM/discard support (for SATA/AHCI or virtio-scsi if configured) plus VirtualBox's handling can free blocks, but dynamic VDI does not always shrink automatically.

To compact (zero free space in guest first):

1. Inside Linux guest:
   ```
   fstrim -av
   ```
   or
   ```
   dd if=/dev/zero of=/zerofile bs=1M; sync; rm /zerofile
   ```
2. On host:
   ```
   VBoxManage modifyhd disk.vdi --compact
   ```

Note: Compaction works only for dynamic VDIs.

## Integrity & Verification

Hashing for transport integrity:

```
sha256sum disk.vdi > disk.vdi.sha256
```

VirtualBox provides basic checks; for deeper inspection use `qemu-img check disk.vdi` (limited validation).

## Use Cases

| Scenario                               | Suitability                                 |
| -------------------------------------- | ------------------------------------------- |
| Local development with VirtualBox      | Ideal                                       |
| Multi-hypervisor distribution          | Convert to common (VMDK/RAW/QCOW2)          |
| Cloud import (AWS/Azure/GCE)           | Convert to required format (RAW, VMDK, VHD) |
| High-performance production (KVM/ESXi) | Prefer native formats (QCOW2/VMDK)          |
| Snapshot-heavy CI pipelines            | Works, but monitor chain depth              |

## When NOT to Use VDI

| Requirement                           | Prefer           |
| ------------------------------------- | ---------------- |
| Native KVM features (backing chains)  | QCOW2            |
| VMware ecosystem integration          | VMDK             |
| Azure upload (fixed VHD requirement)  | VHD              |
| Maximum portability / simplest format | RAW              |
| Block device backend (Ceph/LVM/ZFS)   | Raw block device |

## Security

- No intrinsic encryption; use VirtualBox's VM encryption feature or guest-level (LUKS/BitLocker).
- Always treat downloaded VDI files as untrusted: scan and verify checksums.
- Avoid embedding secrets; use provisioning tools (cloud-init, config management).

## Common Pitfalls

| Pitfall                                   | Effect                    | Mitigation                                    |
| ----------------------------------------- | ------------------------- | --------------------------------------------- |
| Long-lived snapshot chains                | Performance degradation   | Consolidate or clone                          |
| Compact without zeroing free space        | Minimal size reduction    | Zero or fstrim inside guest first             |
| Over-resizing without partition growth    | Wasted space / confusion  | Resize partition & filesystem after VDI grow  |
| Using dynamic VDI for latency-critical DB | Allocation latency spikes | Use fixed VDI or migrate to RAW on fast media |
| Forgetting host backup of base+snapshot   | Incomplete restores       | Back up entire chain or flatten before backup |

## Recommended Workflow (Golden Image)

1. Build base OS VM.
2. Clean/sysprep (remove machine-specific state).
3. Zero free space & compact dynamic VDI.
4. Export VDI + metadata (version, build date).
5. Convert to other formats as needed (RAW, VMDK, QCOW2) in pipeline.
6. Distribute flattened (no snapshots) artifacts.

## Example Multi-Format Pipeline

```
# Start from VirtualBox base build
VBoxManage clonehd base.vdi base-flat.vdi --format VDI
VBoxManage modifyhd base-flat.vdi --compact

# Produce RAW for universal conversions
qemu-img convert -p -O raw base-flat.vdi base.raw

# Produce QCOW2 for KVM
qemu-img convert -p -O qcow2 base.raw base.qcow2

# Produce VMDK (streamOptimized) for OVA packaging
qemu-img convert -p -O vmdk -o subformat=streamOptimized base.raw base.vmdk
```

## Summary

VDI is a practical, flexible format chiefly optimized for VirtualBox usage with dynamic allocation and snapshot layering handled externally. It provides easy conversion pathways to other ecosystems, making it suitable for development and image authoring. For production or specialized performance scenarios, consider migrating to formats native to target hypervisors (QCOW2, VMDK, RAW). Maintain short snapshot chains, compact regularly, and integrate conversion into automated pipelines for consistent, portable image delivery.
