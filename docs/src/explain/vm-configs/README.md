# VM Configuration Files

## Hypervisor / VM configuration & snapshot metadata

> (not disk images themselves, but part of the “image” ecosystem)

- VMware: .vmx (config), .nvram (virtual firmware vars), .vmsd (snapshot metadata), .vmsn (snapshot state, includes memory), .vmss (suspend state).
- VirtualBox: .vbox (XML), .vbox-prev, Logs.
- Hyper-V: .xml config (older), now stored internally in WMI/registry; .vmcx/.vmrs (newer config/runtime state), .bin (VM memory in checkpoints).
- KVM/libvirt: Domain XML definitions, plus separate disk images.
- Parallels: Config.pvs inside .pvm bundle.
- Checkpoint/memory state files: Not disk formats; ephemeral runtime or snapshot state.
- NVRAM / EFI variable stores: For UEFI-based guests (.nvram, .fd, etc).
