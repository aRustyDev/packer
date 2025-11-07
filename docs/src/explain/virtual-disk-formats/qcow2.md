---
title: QCOW2
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# QCOW2

`QCOW2` (QEMU Copy-On-Write version 2) is the modern, feature-rich virtual disk image format used primarily in QEMU/KVM ecosystems. It supports sparse allocation, internal snapshots, backing (base) images, optional compression, and flexible metadata extensions. It supersedes the legacy `QCOW` (v1) and other experimental formats (like `QED`).

## Why QCOW2

- Space efficiency: Allocates clusters on demand (thin‑provisioned).
- Snapshot capability: Internal snapshots and external overlay chaining (via backing files).
- Portability: Widely supported by `qemu-img`, libvirt, and tooling used in cloud/image pipelines.
- Extensibility: Header supports feature flags (e.g., lazy refcounts, extended L2 tables).
- Integration: Works well with block storage backends (RBD, NBD, LVM via layered approach).

## Core Features

| Feature                  | Description                                                              |
| ------------------------ | ------------------------------------------------------------------------ |
| Sparse allocation        | Unwritten regions are not physically stored, reducing size.              |
| Backing files            | COW layering: a child references a read-only base image.                 |
| Internal snapshots       | Metadata stores state of disk at points in time (not memory).            |
| Copy-on-write            | Modified clusters are written to the top image; base remains intact.     |
| Compression (optional)   | Per-cluster compression (trade-offs: CPU vs space/speed).                |
| Encryption (legacy)      | Obsolete internal AES keys; today prefer external LUKS on top.           |
| Lazy refcounts           | Improves snapshot deletion performance.                                  |
| Discard/TRIM support     | Enables space reclamation on underlying storage when guest deletes data. |
| Backing chain inspection | `qemu-img info` reveals lineage of layered images.                       |

## Internal Structure (Simplified)

- Header: Magic (`QFI`), version, feature flags, cluster size, refcount table offsets.
- L1 Table: Points to L2 tables; governs logical-to-physical block mapping.
- L2 Tables: Map guest cluster indices to data cluster offsets (or zero/backing references).
- Refcount Table / Blocks: Track number of references to clusters (for snapshot safety & reclamation).
- Snapshots (optional): Embedded metadata blocks referencing point-in-time refcount states.
- Data Clusters: Actual guest data (optionally compressed/encrypted).
- Backing File Pointer: Path (or JSON block driver options) linking to a base image.

## Typical Use Cases

- Golden image distribution for KVM/libvirt.
- Ephemeral VM disk overlays on top of a base OS image (fast provisioning).
- Template baking in CI pipelines (apply updates, then commit as new QCOW2).
- Development environments needing fast cloning + rollback points.
- Nested copy-on-write layering for differential build testing.

## Creating & Converting

Create from RAW:

```
qemu-img convert -p -O qcow2 disk.raw disk.qcow2
```

Create with specific cluster size (e.g., 1 MiB clusters for large sequential workloads):

```
qemu-img create -f qcow2 -o cluster_size=1048576 vm.qcow2 40G
```

View info:

```
qemu-img info vm.qcow2
```

Convert to RAW (e.g., for cloud import):

```
qemu-img convert -p -O raw vm.qcow2 disk.raw
```

## Backing File Workflow

1. Base image: `base.qcow2` (contains OS).
2. Create overlay:
   ```
   qemu-img create -f qcow2 -b base.qcow2 overlay.qcow2
   ```
3. Run VM using `overlay.qcow2`. All changes stored only in overlay.
4. Commit changes back:
   ```
   qemu-img commit overlay.qcow2
   ```
   (Writes modified clusters into the backing image—use cautiously.)
5. Or flatten (remove dependency):
   ```
   qemu-img convert -O qcow2 overlay.qcow2 flattened.qcow2
   ```

## Internal Snapshots vs External Overlays

| Aspect                 | Internal Snapshot       | External Overlay (backing file)  |
| ---------------------- | ----------------------- | -------------------------------- |
| Tooling                | `qemu-img snapshot`     | `qemu-img create -b base`        |
| Portability            | Lower (embedded state)  | Higher (explicit layering)       |
| Granularity            | Disk-only               | Disk-only                        |
| Deletion Complexity    | Refcount adjustments    | Remove overlay (simple)          |
| Recommended Modern Use | Limited (special cases) | Preferred for layering workflows |

Most orchestration layers (libvirt, OpenStack) prefer external overlays for clarity and simplified cleanup.

## Performance Considerations

- Cluster Size:
  - Larger clusters reduce metadata overhead for large sequential writes.
  - Smaller clusters improve space efficiency for sparse small-file workloads.
- Fragmentation:
  - Many small random writes can fragment host filesystem; consider periodic `qemu-img convert` to defragment.
- Cache Modes (runtime, not format-specific):
  - `writeback`, `none`, `directsync` interact with host durability guarantees; choose per workload.
- Preallocation:
  - `qemu-img create -f qcow2 -o preallocation=metadata` reduces runtime metadata allocations.
  - Full preallocation reduces thin-provision space savings but can improve latency predictability.

## Compression & Encryption

- Built-in compression is per cluster and opportunistic. For modern practice:
  - Use host-level filesystem compression (e.g., ZFS, Btrfs) OR
  - Use external tooling to recompress offline.
- Encryption:
  - Legacy internal AES is deprecated.
  - Prefer wrapping raw/QCOW2 inside a LUKS block device or use storage backend encryption (Ceph, dm-crypt, etc).

## Discard (TRIM) Handling

Enable guest to issue discard:

- Virtio-blk or virtio-scsi with `discard=unmap`.
- Improves space reclamation in sparse QCOW2 (freed clusters become unallocated).
- Confirm host filesystem supports hole punching (e.g., ext4, XFS, ZFS semantics vary).

## Recommended Best Practices

| Practice                                                                  | Rationale                                                  |
| ------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Use QCOW2 for dev/test with snapshots; RAW for high-throughput production | Minimizes overhead on hot paths where features not needed. |
| Keep backing chains short (1–2 layers)                                    | Long chains add lookup overhead and complexity.            |
| Periodically flatten heavily mutated overlays                             | Reduces fragmentation and improves I/O predictability.     |
| Version/tag golden base images (include build metadata)                   | Traceability and reproducible rebuilds.                    |
| Avoid internal snapshots for long-term retention                          | External overlays easier to manage and export.             |
| Use `qemu-img check` for integrity after abnormal host crashes            | Detects refcount inconsistencies early.                    |

## Common Pitfalls

- Excessive backing chain depth → degraded performance.
- Forgetting discard support → disk appears to grow indefinitely despite guest deletions.
- Relying on embedded encryption → insecure/outdated; migrate to LUKS.
- Using too small cluster size for large sequential workloads → metadata overhead rises.
- Committing overlays unintentionally → loss of rollback point.

## Migration from Legacy Formats

Convert from QCOW (v1), QED, VMDK, VDI, VHD(X):

```
qemu-img convert -p -O qcow2 old.img new.qcow2
```

Validate integrity post-conversion (`qemu-img check new.qcow2`) before promoting image to production use.

## Inspection & Maintenance

- Integrity check:
  ```
  qemu-img check vm.qcow2
  ```
- Reclaim space (if underlying FS supports):
  - Ensure guest runs fstrim (Linux) or regular defragmentation + free space consolidation (Windows).
- Defragment / optimize:
  ```
  qemu-img convert -O qcow2 vm.qcow2 vm-optimized.qcow2
  mv vm-optimized.qcow2 vm.qcow2
  ```

## When NOT to Use QCOW2

| Scenario                                               | Prefer                                        |
| ------------------------------------------------------ | --------------------------------------------- |
| Highest sequential throughput, minimal feature needs   | RAW on dedicated block device (LVM, ZFS zvol) |
| Storage-level replication (Ceph RBD, iSCSI LUN)        | Direct block backend (skip file format)       |
| Guest clustering requiring shared SCSI reservations    | Specialized shared block solutions            |
| Heavy I/O analytics pipeline with predictable datasets | RAW + host filesystem tuning                  |

## Summary

QCOW2 provides a mature, flexible virtual disk format balancing space efficiency with advanced features (backing images, snapshots, sparse allocation). It is ideal for development, image baking, and dynamic provisioning workflows. For pure performance or large-scale production with minimal feature requirements, RAW or direct block backends may be superior. Maintain short backing chains, avoid deprecated internal encryption, leverage discard/trim, and periodically validate and optimize images to sustain reliability.
