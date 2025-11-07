---
title: QCOW
deprecated: true
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# QCOW

`QCOW` (often retroactively called "qcow v1") is the original QEMU copy‑on‑write disk format predating `QCOW2`. It introduced a sparse, copy‑on‑write allocation model but lacks the performance, reliability, and feature improvements added in later generations.

## Status

- Deprecated in favor of `QCOW2`.
- Rarely encountered except in very old archives or legacy VM images.
- Modern tooling may still read qcow v1 but should not produce new images in this format.

## Limitations vs QCOW2

| Aspect              | QCOW (v1)                    | QCOW2                                              |
| ------------------- | ---------------------------- | -------------------------------------------------- |
| Snapshot robustness | Basic / limited              | Mature internal snapshot support                   |
| Performance         | Slower metadata handling     | Improved allocation & caching                      |
| Backing files       | Supported but less efficient | Supported with better semantics                    |
| Compression         | Primitive / external tooling | Optional internal compressed clusters              |
| Encryption          | Not standardized / weak      | Integrated AES (deprecated) + prefer LUKS layering |
| Extensibility       | Constrained                  | Extended header fields allow new feature flags     |

## Why Migrate

- Better tooling support (libvirt, qemu-img workflows focus on QCOW2).
- Reduced corruption risk and improved consistency semantics.
- Access to features (lazy refcounts, discard/TRIM handling, subcluster allocation in newer QCOW2 enhancements).

## Identification

A legacy qcow v1 image typically has a simpler header lacking QCOW2 magic (`QFI` version 2). Use:

```
qemu-img info old.qcow
```

to confirm format version. If reported simply as `qcow` and not `qcow2`, treat it as a candidate for conversion.

## Conversion

```
qemu-img convert -p -O qcow2 old.qcow new.qcow2
```

Optionally convert directly to RAW for maximum portability:

```
qemu-img convert -p -O raw old.qcow disk.raw
```

## Risks When Retaining QCOW (v1)

- Potential incompatibility with newer snapshot/orchestration tooling.
- Less efficient space usage and I/O patterns.
- Harder integration with modern backup / incremental replication workflows.

## Recommendation

Do not create new qcow v1 images. Convert any remaining qcow (v1) artifacts to `QCOW2` (preferred) or `RAW` if performance and simplicity outweigh snapshot/feature needs.

## Summary

`QCOW` (v1) is a legacy QEMU copy-on-write disk format superseded by `QCOW2`. Migrate all remaining instances to maintained formats to gain improved reliability, performance, and feature support.
