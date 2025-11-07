---
title: Cloop
deprecated: true
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# Cloop

`cloop` (Compressed Loopback) was an early Linux compressed block device image format used primarily on live CDs (notably KNOPPIX) before widespread adoption of SquashFS for compressed root filesystems.

## Purpose & Use Case (Historical)

- Enabled large, read-only filesystem images to fit on limited optical media by compressing data blocks.
- Mapped compressed blocks through the loop device so the kernel could access files transparently.
- Common in early live / rescue distributions for minimizing media size.

## Structure & Mechanics (Simplified)

- Fixed-size compressed blocks (often 64 KB uncompressed) indexed by a table.
- Kernel module performed on-the-fly decompression when blocks were read.
- Provided a block-oriented interface rather than a file-based diff/layer model.

## Why It Faded

| Factor      | Reason cloop declined                                                                         |
| ----------- | --------------------------------------------------------------------------------------------- |
| Flexibility | SquashFS offered better compression ratios, larger block sizes, and improved random access.   |
| Maintenance | SquashFS became mainlined and more actively maintained; cloop remained niche.                 |
| Ecosystem   | Tooling and distro build systems standardized on SquashFS for live images.                    |
| Features    | SquashFS added XATTRs, better metadata compression, and integration with overlayfs workflows. |

## Modern Replacements

- SquashFS (paired with overlayfs for live/persistent sessions).
- Compressed disk images inside general-purpose formats (e.g., QCOW2 with compression) for VM contexts.
- Container images (layered tar archives) for application-level distribution.

## Conversion / Migration Notes

There is rarely a need to “convert” cloop today:

1. Mount the legacy cloop image (if kernel/module available).
2. Copy out the filesystem contents to a staging directory.
3. Repack with `mksquashfs` or generate a full VM disk image (RAW/QCOW2) if moving to virtual machine distribution.

## When You Still Encounter It

- Archival mirrors of very old live distributions.
- Forensic analysis of historical media.
- Niche embedded environments frozen on legacy tooling.

## Risks & Limitations

- Kernel/module availability on modern distros may be absent (requiring custom build).
- Performance and compression efficiency inferior to current alternatives.
- No snapshotting or writable layering—strictly read-only.

## Recommendation

Treat cloop as a deprecated artifact:

- Do not use for new builds.
- Migrate legacy images to SquashFS or a standard VM disk format.
- Archive original media for provenance if required, but standardize runtime assets on maintained formats.

## Summary

`cloop` = legacy compressed block device format for early live Linux media. Superseded by SquashFS and other modern compression + layering approaches. Retain only for historical or forensic purposes; replace in any active build pipeline.
