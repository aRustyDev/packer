# Tips: Images

Practical advice:

- For maximum portability when distributing an appliance:
  - Provide an OVF (descriptor + disks) or an OVA plus a README.
- For iterative development with snapshots (KVM/libvirt):
  - QCOW2.
- For performance-sensitive production on KVM with external snapshot orchestration:
  - RAW on LVM/ZFS + external backup tooling.
- For VMware distribution:
  - streamOptimized VMDK inside OVA.
- For Azure import:
  - Fixed-size (not dynamic) VHD (page-aligned).
- For AWS import:
  - RAW or VMDK; then convert to AMI (EBS snapshot).
- For lab multi-hypervisor interchange:
  - Start from RAW and maintain conversion scripts to VMDK, VDI, VHDX.
