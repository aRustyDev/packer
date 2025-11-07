---
title: RAW
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# RAW

`RAW` is the simplest virtual disk representation: a byte‑for‑byte mapping of the guest's logical disk blocks with no additional metadata, headers, compression, or encryption.

## Key Characteristics

- No container metadata (pure block stream).
- Supports any partition table (MBR, GPT) or filesystem recognized by guest/host tools.
- Max size limited only by host filesystem / storage backend.
- Amenable to host-level sparse allocation (if created as a sparse file).
- Universally convertible: all hypervisor and image tooling can read/write raw bytes.
- No intrinsic features: no built-in snapshots, compression, encryption, backing chains.

## When to Use RAW

| Scenario                                       | Why RAW Helps                                                            |
| ---------------------------------------------- | ------------------------------------------------------------------------ |
| Performance-critical sequential I/O            | Eliminates indirection / metadata lookups present in featureful formats. |
| Base image for conversion pipelines            | Acts as canonical source to produce VMDK, QCOW2, VHDX, etc.              |
| Cloud imports (AWS, GCE, OpenStack)            | Many import workflows prefer or internally convert to RAW.               |
| Direct block backend (LVM, ZFS zvol, Ceph RBD) | Using a block device is essentially RAW semantics.                       |
| Forensic or archival integrity                 | Exact byte-for-byte reproducibility (easy to hash).                      |

## Creation

Allocate sparse file of 40G:

```
dd if=/dev/zero of=disk.raw bs=1 count=0 seek=40G
```

Or with fallocate (may preallocate extents):

```
fallocate -l 40G disk.raw
```

Partition and format (example):

```
parted disk.raw --script mklabel gpt mkpart primary ext4 1MiB 100%
losetup --find --partscan disk.raw
mkfs.ext4 /dev/loopX
```

(Detach loop with `losetup -d /dev/loopX` when done.)

## Conversion Examples

RAW -> QCOW2:

```
qemu-img convert -p -O qcow2 disk.raw disk.qcow2
```

RAW -> VMDK (streamOptimized):

```
qemu-img convert -p -O vmdk -o subformat=streamOptimized disk.raw disk.vmdk
```

QCOW2 -> RAW (flatten):

```
qemu-img convert -p -O raw base.qcow2 base.raw
```

Verify:

```
qemu-img info disk.raw
```

## Sparse vs Preallocated

| Mode               | Pros                                          | Cons                                    |
| ------------------ | --------------------------------------------- | --------------------------------------- |
| Sparse file        | Saves space for uninitialized blocks          | Fragmentation; host FS must track holes |
| Fully preallocated | Predictable performance; avoids fragmentation | Consumes full capacity immediately      |

To identify sparseness:

`du -h disk.raw` (physical) vs `ls -lh disk.raw` (logical)

## Performance Notes

- No metadata lookups: each guest block maps directly to host offset.
- Host filesystem fragmentation can still hurt random I/O; use contiguous allocation or place on raw block (LVM LV).
- Alignment: create partitions aligned to 1 MiB boundaries to optimize underlying storage.
- Discard/TRIM: if underlying FS supports hole punching and guest issues discard, space can be reclaimed (requires loop or virtio-blk with discard).

## Snapshots

RAW itself has no snapshot mechanism. Implement snapshots by:

- Storage layer (LVM snapshots, ZFS clones, Ceph snapshots).
- External copy-on-write overlay formats (create QCOW2 with RAW as backing).

Example overlay:

```
qemu-img create -f qcow2 -b disk.raw overlay.qcow2
```

## Integrity & Hashing

```
sha256sum disk.raw > disk.raw.sha256
```

Because RAW lacks internal metadata, integrity verification is straightforward.

## Security

- No built-in encryption; layer with LUKS (inside guest) or dm-crypt / storage encryption externally.
- No metadata = less attack surface in parsing, but also no tamper-detection.

## Compression Strategy

- Do not store production runtime disks compressed inline; instead compress offline backups:

```
gzip -c disk.raw > disk.raw.gz
```

Or convert to QCOW2 with compression for distribution only.

## Common Pitfalls

| Pitfall                                                                     | Mitigation                                                                   |
| --------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Accidental full allocation of sparse file (e.g., dd with large zero writes) | Use fallocate carefully; monitor with du.                                    |
| Losing snapshot capability                                                  | Use storage-layer snapshots or COW overlay formats.                          |
| Oversized images imported to cloud                                          | Shrink filesystem + partition, then use `qemu-img convert` or `virt-resize`. |
| Misaligned partition table                                                  | Use modern partition tools with MiB alignment.                               |

## Cloud Import Considerations

- AWS VM Import: Provide a RAW in S3 or convert before upload (Result becomes EBS snapshot → AMI).
- Azure requires VHD (fixed); convert RAW → VHD with qemu-img.
- GCE will accept RAW tar (disk.raw inside archive) or convert from QCOW2/VMDK.

## When NOT to Use RAW

| Scenario                                                               | Better Choice                            |
| ---------------------------------------------------------------------- | ---------------------------------------- |
| Need internal snapshots/backing chains                                 | QCOW2 / VMDK with delta                  |
| Need built-in compression for distribution                             | QCOW2 (compressed clusters)              |
| Multi-tenant encrypted at-rest requirement                             | LUKS + RAW, or encrypted storage backend |
| Working set dominated by small random writes with need for thin clones | QCOW2 overlay strategy                   |

## Lifecycle & Maintenance

- Keep authoritative golden RAW image immutable; derive feature formats (QCOW2, VMDK) from it.
- Version using filename or metadata tags: `app-base-2024-11-07.raw`
- Regenerate periodically rather than chaining many overlays.

## Removal / Shrink Workflow (Example)

1. Inside guest: zero free space (Linux: `fstrim -av` or `zerofill`).
2. Detach guest; if not sparse, convert:

```
qemu-img convert -p -O raw disk.raw compacted.raw
```

3. Replace original after checksum verification.

## Summary

RAW is the foundational, featureless virtual disk representation offering maximal compatibility and minimal overhead. Pair it with external mechanisms (storage snapshots, encryption, overlays) for advanced capabilities. Use RAW as a canonical build artifact and convert outward to richer formats as workflow requirements dictate.
