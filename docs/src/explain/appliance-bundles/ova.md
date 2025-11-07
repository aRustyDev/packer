---
title: OVA
assumed_roles:
  - .aim/roles/virtualization-engineer.md
---

# OVA

- OVA vs OVF: OVA = TAR-wrapped OVF set. OVF = descriptor + separate disks.
- **OVA**: Single TAR archive containing an OVF package (descriptor + disks + manifests). Conveys an appliance in one file.

## What Is It?

An OVA (Open Virtual Appliance) is a distribution/packaging convenience: a single TAR archive that bundles an OVF descriptor (`.ovf` XML), one or more virtual disk files (commonly streamOptimized VMDK, but can be others), a manifest file (`.mf` with SHA256/SHA1 digests), and optionally a certificate (`.cert`). It is not itself a distinct virtual disk format; it is a transport container for an OVF set.

## Structure (Typical Contents)

```
appliance.ovf        # OVF XML descriptor (hardware, references to disks)
disk0.vmdk           # Virtual disk (often streamOptimized for portability)
disk1.vmdk           # (Optional) additional disks
appliance.mf         # Manifest with checksums of ovf + disk files
appliance.cert       # (Optional) Signature/certificate
```

All files are stored at the TAR root (no subdirectories per spec best practice).

## Common Use Cases

- Distributing a vendor “virtual appliance” (pre-hardened application VM).
- Moving a VM between hypervisors that can import OVF/OVA (VMware products, VirtualBox, some KVM/libvirt tooling with conversion).
- Archiving a point-in-time packaged template (more portable than a hypervisor‑specific directory layout).

## Advantages

- Single file simplifies transport (email, object storage, checksum verification).
- Manifest enables integrity verification on import.
- Widely recognized across multiple hypervisor ecosystems (VMware, VirtualBox).
- Stream-optimized disk reduces size vs flat disk while remaining convertible.

## Limitations

- Still needs expansion: import processes must untar, validate manifest, then register the VM.
- Large single file can make partial transfers or resumable uploads harder vs separate files.
- Not all disk formats inside are equally portable—VMDK (streamOptimized) is most common; exotic formats may reduce compatibility.
- Specification evolution (OVF) means older consumers may reject newer feature sets (e.g., advanced virtual hardware descriptors).

## OVA vs OVF (When to Use Which)

| Criterion           | OVF (directory)                     | OVA (single TAR)                |
| ------------------- | ----------------------------------- | ------------------------------- |
| Transport           | Multiple files                      | One file                        |
| Incremental updates | Easier (replace a single disk file) | Harder (repack archive)         |
| Integrity checking  | Manifest still works                | Manifest + single-file checksum |
| Large disk handling | Can handle sparse separately        | Single monolithic transfer      |
| Streaming import    | Some tools can stream TAR           | Straightforward to stream       |

Choose OVF when iterative updates are frequent; OVA when distribution convenience dominates.

## Creation (Typical Workflow)

1. Prepare / shut down the source VM.
2. (VMware) Use `ovftool` or vSphere Client to export:
   - Example: `ovftool vi://user@esxi-host/vmName appliance.ova`
3. (VirtualBox) Use `VBoxManage export`:
   - Example: `VBoxManage export <vm> --output appliance.ova`
4. Verify manifest digests:
   - `tar -xf appliance.ova appliance.mf`
   - `sha256sum -c appliance.mf`

## Validation

- Use `ovftool appliance.ova` (VMware) to lint.
- Open the `.ovf` XML to verify hardware sections (e.g., CPU count, VirtualSystemType).
- Confirm disk capacity vs allocation (streamOptimized size may be smaller than logical size).

## Conversion / Extraction

- Extract: `tar -xf appliance.ova`
- Convert disk (example to RAW): `qemu-img convert -p -O raw disk0.vmdk disk0.raw`
- Repackage (after modification—be cautious):
  1. Update or regenerate `.mf` (`sha256sum *.ovf *.vmdk > appliance.mf`)
  2. Create OVA: `tar -cvf new-appliance.ova appliance.ovf disk0.vmdk appliance.mf`

(Altering vendor appliances may void support; verify licensing.)

## Security & Integrity

- Always verify manifest signatures or at least digest hashes before import.
- Treat unknown vendor OVAs like untrusted binaries: scan or deploy in quarantine network segment first.
- Remove embedded credentials/scripts before production cloning if unpacking and inspecting.

## Best Practices

- Include a concise product/version naming in OVF `VirtualSystem` and OVA filename (e.g., `myapp-1.4.2-hardened.ova`).
- Keep disk count minimal (consolidate where practical) to streamline import.
- Use streamOptimized VMDK for balance of size and broad compatibility.
- Document default credentials and post-import hardening steps in an accompanying README (distributed separately or as annotation properties).

## Pitfalls

- Mismatch between declared virtual hardware version and target hypervisor capabilities causes import failures.
- Missing or stale manifest file leads to integrity warnings or rejections.
- Oversized thin-provisioned expectations: logical disk size in OVF may exceed host free space if not accounted for.
- Assuming OVA implies security hardening—content quality varies widely.

## Dealing with Large OVAs

- Provide external checksum file (e.g., `appliance.ova.sha256`) for quick integrity validation pre-import.
- Consider splitting at transport layer (e.g., `split -b 2G appliance.ova part-`) and reassemble (`cat part-* > appliance.ova`) at destination.

## Summary

- OVA = Convenience wrapper around an OVF package (single TAR file).
- Not a disk format; encapsulates descriptor + disk(s) + manifest.
- Ideal for distribution; OVF directory may be better for iterative development.
- Use tooling (`ovftool`, `VBoxManage`) for reliable generation and validation.
