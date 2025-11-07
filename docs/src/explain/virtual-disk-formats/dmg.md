---
title: DMG
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# DMG (Apple Disk Image)

`DMG` is the native macOS disk image container format used primarily for software distribution, packaging, and archival on Apple platforms. While it can encapsulate a filesystem (HFS+, APFS) and appear as a mounted volume, it is not typically employed as a virtual machine runtime disk format in hypervisor workflows (which prefer RAW, QCOW2, VMDK, VHDX, etc.). Instead, DMG serves as a flexible wrapper offering compression, optional encryption, and sparse storage capabilities for macOS application delivery and system images.

## What It Is (and Is Not)

- IS: A container that holds a block-image representation of a filesystem (HFS+, APFS) with optional compression/encryption metadata.
- IS: A mountable volume via macOS (`hdiutil attach`), often read-only for distribution.
- IS NOT: A hypervisor-native virtual disk for general-purpose VM execution (outside niche macOS virtualization workflows).
- IS NOT: A snapshotting or copy‑on‑write format in the manner of QCOW2/VMDK delta chains (though sparse variants grow on demand).

## Variants

| Variant / Extension | Description                                        | Notes                                                |
| ------------------- | -------------------------------------------------- | ---------------------------------------------------- |
| .dmg                | Standard disk image (may be compressed/encrypted). | Most common distribution artifact.                   |
| .sparseimage        | Single-file sparse grow-on-write DMG.              | Expands up to a declared max size.                   |
| .sparsebundle       | Directory bundle of banded sparse segments.        | Better for Time Machine / large incremental changes. |
| Read-only DMG       | Fixed content, optionally compressed.              | Ideal for software installers.                       |
| Read-write DMG      | Mutable content (development, staging).            | Not recommended for final distribution.              |

## Compression Methods

Common formats supported internally (selected, version-dependent):

- zlib (default DEFLATE)
- bzip2
- lzfse (modern Apple high-ratio/fast)
- LZMA (in some toolchains)
- ADC (legacy)
  Trade-offs: Higher compression increases CPU cost during attach; choose based on distribution size vs user experience.

## Encryption

- Supports AES-128 or AES-256 (password or keychain-based).
- Encrypted DMGs prompt for credentials at mount time.
- Use for protecting confidential payloads in transit; beware of performance overhead and recovery complexity.

## Sparse vs Banded (sparsebundle)

| Aspect                                | sparseimage (single file)           | sparsebundle (banded directory)     |
| ------------------------------------- | ----------------------------------- | ----------------------------------- |
| Incremental backup friendliness       | Poor (changes rewrite large blocks) | Better (changes isolated to bands)  |
| Large file growth behavior            | Can fragment substantially          | More granular growth                |
| Transfer efficiency (rsync, cloud)    | Less efficient (whole file diff)    | More efficient (changed bands only) |
| Recommended for large evolving images | No                                  | Yes                                 |

## Typical Use Cases

- macOS application distribution (drag-and-drop app bundles).
- Packaging CLI tools or installers with code signing & Gatekeeper metadata.
- Archiving system states or pre-configured development environments.
- Delivering firmware utilities or driver packages for macOS hosts.
- Hosting a custom APFS/HFS+ volume with provisioning scripts (rare for VM base image creation today).

## DMG vs RAW (Virtualization Context)

| Criterion          | DMG                        | RAW                  |
| ------------------ | -------------------------- | -------------------- |
| Primary purpose    | Distribution / mounting    | Runtime VM disk      |
| Hypervisor support | Limited (needs conversion) | Universal            |
| Features           | Compression, encryption    | None (byte-for-byte) |
| Mutability (dist)  | Usually read-only          | Read/write           |
| Conversion needed  | Yes (for most hypervisors) | Already native       |

To use a DMG as a base for a VM disk, convert it to a raw image first.

## Internal Structure (High-Level)

A DMG wraps:

- Header (plist or binary metadata defining block map).
- Data blocks (optionally compressed/encrypted).
- Checksum / integrity information (CRC32, etc.).
- Footer (repeat or finalize metadata for validation).
  For sparsebundle: A directory with `Info.plist`, `token`, band files (e.g., `bands/0`, `bands/1`, ...).

## Creation Examples

Create a read-only compressed DMG from a staging directory:

```
hdiutil create -volname "MyApp" -srcfolder ./staging -format UDZO -imagekey zlib-level=9 MyApp.dmg
```

Create an AES-256 encrypted DMG (prompt for passphrase):

```
hdiutil create -volname "SecurePayload" -srcfolder ./payload \
  -encryption AES-256 -format UDZO SecurePayload.dmg
```

Create a writable sparseimage (max size 20G):

```
hdiutil create -size 20g -type SPARSE -fs APFS -volname DevData DevData.sparseimage
```

Create a sparsebundle (better incremental behavior) of 50G max:

```
hdiutil create -size 50g -type SPARSEBUNDLE -fs APFS -volname DevBundle DevBundle.sparsebundle
```

## Mounting / Attaching

Attach (auto-mount):

```
hdiutil attach MyApp.dmg
```

Detach:

```
hdiutil detach /Volumes/MyApp
```

Attach without browsing (no Finder open):

```
hdiutil attach -nobrowse SecurePayload.dmg
```

## Inspecting

Show info:

```
hdiutil imageinfo MyApp.dmg
```

Verify checksum:

```
hdiutil verify MyApp.dmg
```

## Converting to RAW (For Virtualization)

If a DMG contains a bootable macOS filesystem and you need a raw block image (e.g., for qemu):

```
hdiutil convert BaseSystem.dmg -format UDRW -o BaseSystem.img
```

Then optionally convert to QCOW2:

```
qemu-img convert -p -O qcow2 BaseSystem.img BaseSystem.qcow2
```

Note: Modern macOS virtualization often uses pre-created system images or automated installation rather than distributing DMGs for hypervisor root disks.

## Integrity & Signing

- DMGs can be code-signed (for Gatekeeper acceptance).
- Standard practice for application distribution: sign .app bundle + DMG and notarize.
- Provide SHA256 checksum for users:
  ```
  shasum -a 256 MyApp.dmg > MyApp.dmg.sha256
  ```

## Security Considerations

| Aspect       | Recommendation                                                          |
| ------------ | ----------------------------------------------------------------------- |
| Encryption   | Use AES-256 for sensitive content; manage passphrases securely.         |
| Notarization | Notarize DMG distributing macOS apps to avoid Gatekeeper warnings.      |
| Tamper proof | Combine code signing + external checksum verification.                  |
| Secrets      | Avoid embedding plaintext secrets; prefer runtime retrieval mechanisms. |

## Performance Notes

- Compressed DMGs trade CPU for reduced download size.
- Large sparseimages can fragment; periodic conversion to a compact read-only DMG improves distribution efficiency.
- Sparsebundle band size impacts rsync efficiency; default sizes typically acceptable.

## Migration / Alternatives

| Need                             | Prefer                   |
| -------------------------------- | ------------------------ |
| Cross-platform VM disk           | RAW / QCOW2 / VMDK       |
| Linux distribution artifact      | ISO / tarball            |
| Windows application distribution | MSI / ZIP                |
| Frequent incremental growth      | sparsebundle (local)     |
| Immutable release artifact       | Compressed read-only DMG |

## Common Pitfalls

| Pitfall                                       | Consequence                                | Mitigation                          |
| --------------------------------------------- | ------------------------------------------ | ----------------------------------- |
| Using DMG as VM runtime disk directly         | Poor tooling support / conversion overhead | Convert to RAW/QCOW2 first          |
| Distributing writable DMG                     | Risk of unintended mutation                | Use read-only compressed format     |
| Weak encryption (AES-128) for sensitive data  | Reduced security posture                   | Prefer AES-256                      |
| Neglecting notarization/signing               | User trust issues / Gatekeeper blocks      | Sign & notarize release DMGs        |
| Large dynamic sparseimage without maintenance | Fragmentation, inflated physical size      | Periodic compact or convert to UDZO |

## Best Practices

- Use `UDZO` (zlib compressed) or `UDBZ` (bzip2) only if size matters more than speed; consider `ULZF` (lzfse) when available for balance.
- Keep distribution DMGs read-only and signed.
- Provide checksum & signature metadata externally (e.g., `.sha256`, `.asc`).
- Avoid DMG as a multi-hypervisor interchange format—use RAW as golden base instead.
- For iterative macOS build artifacts, use sparsebundle locally, then finalize into a compressed DMG for release.

## Summary

DMG is a macOS-centric packaging and distribution container offering compression, encryption, and sparse allocation variants. It is not a general virtualization disk format but can be a precursor artifact that is later converted into RAW or QCOW2 for VM use. Employ read-only, signed, and notarized DMGs for application delivery; reserve sparse variants for local development convenience. For cross-platform virtualization workflows, pivot to RAW (as canonical) and generate target hypervisor formats from there.
