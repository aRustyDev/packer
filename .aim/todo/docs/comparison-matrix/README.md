# matrix categories with suggested dimensions (columns) and the kinds of rows they would contain.

1. Virtual Disk Format Feature Matrix
   Rows: RAW, QCOW2, VMDK (subformats), VHD, VHDX, VDI, HDD (Parallels), DMG (macOS distribution), AVHDX (delta), AVHD (legacy), COW, QCOW (v1), QED, VPC, cloop
   Columns: Thin provisioning, Internal snapshots, External overlays, Backing file support, Max disk size, Sparse efficiency, Compression (native), Encryption (native), TRIM/discard support, Sector size options, Tooling ubiquity, Cloud import friendliness, Deprecated status.

2. Performance / Overhead Matrix
   Rows: Same disk formats
   Columns: Metadata lookup overhead (low/medium/high), Random read latency impact (baseline vs chain), Sequential throughput potential, Snapshot performance impact, Fragmentation susceptibility, Merge/consolidation cost, Typical cluster/block size tunability, Recommended workload archetypes (DB, web, CI, analytics).

3. Portability & Interoperability Matrix
   Rows: Disk formats + appliance bundles (OVA, OVF, BOX, XVA, RDI)
   Columns: Native hypervisors, Conversion tooling availability, Cross-cloud acceptance (AWS, Azure, GCE, OpenStack), Need for flattening before migration, Interchange clarity (schema openness), Single-file distribution convenience, Multi-VM support, Ecosystem maturity.

4. Snapshot / Layering Strategy Matrix
   Rows: QCOW2 internal snapshot, QCOW2 external overlay, VMDK delta chain, VHDX differencing, AVHDX chain, LVM snapshot, ZFS clone, Ceph RBD snapshot
   Columns: Creation speed, Read amplification effect, Write amplification effect, Merge complexity, Maximum practical depth, Tooling support, Portability of snapshot state, Recommended retention window.

5. Cloud Import Compatibility Matrix
   Rows: RAW, VMDK (streamOptimized, monolithicSparse), VHD (fixed), VHDX, QCOW2, OVF/OVA package
   Columns: AWS VM Import, Azure custom image, GCE import, OpenStack Glance (common drivers), Required pre-conversion steps, Size alignment constraints, Typical failure causes, Preferred canonical source.

6. Obsolescence / Risk Matrix (Legacy vs Active)
   Rows: cloop, COW, QCOW (v1), QED, VPC, AVHD, XVA, RDI vs QCOW2, VHDX, VMDK, RAW
   Columns: Current support status, Risk of corruption vs modern equivalent, Migration effort (low/medium/high), Tooling availability today, Security feature gaps, Urgency to migrate (1–5), Recommended target format.

7. Space Efficiency vs Complexity Matrix
   Rows: RAW (sparse file), QCOW2 (thin), VMDK thin, VMDK eagerZeroedThick, VHDX dynamic, VHDX fixed, ZFS zvol (thin/dedup), Ceph RBD
   Columns: Provisioning overhead, Wasted space risk, Reclamation ease (TRIM effectiveness), Fragmentation tendency, Compression capability (native / external), Operational complexity, Monitoring requirements.

8. Encryption & Data Protection Matrix
   Rows: QCOW2 (legacy AES), QCOW2 + LUKS layer, VMDK + vSphere VM encryption, VHDX + BitLocker in guest, RAW + dm-crypt, Ceph RBD (server-side), Storage array encryption
   Columns: At-rest coverage scope, Key management locus, Performance impact, Portability impact, Backup interaction complexity, Granularity (disk/volume/VM), Recommended modernity.

9. Build Pipeline Integration Matrix
   Rows: Formats in pipeline stages (Base builder, Intermediates, Distribution artifact, Archival)
   Columns: Stage use (Y/N), Creation tools, Cleanup actions (sysprep, cloud-init), Snapshot technique, Conversion targets, Integrity verification method, Version/tag strategy.

10. Conversion Complexity Matrix
    Rows: Pairwise source→target (e.g., QCOW2→VMDK, VMDK→RAW, VHDX→VHD, DMG→RAW, HDD→RAW)
    Columns: One-step with qemu-img? (Y/N), Need intermediate flatten? (Y/N), Metadata loss risk, Performance tuning lost, Typical size change (%), Time cost (relative), Common pitfalls.

11. Lifecycle Governance Matrix
    Rows: Disk formats + bundle types
    Columns: Version tagging ease, Integrity verification mechanism (manifest/checksum/signature), Recommended rebuild cadence, Snapshot pruning policy, Automation readiness, Audit/logging needs, SBOM feasibility.

12. Use-Case Decision Matrix
    Rows: Representative workloads (High IOPS DB, General web VM, CI ephemeral runner, Large analytics dataset, Legacy recovery image, Multi-VM appliance distribution, Cross-cloud golden image)
    Columns: Recommended format, Alternate acceptable, Snapshot model, Base image rebuild frequency, Compression recommended (Y/N), Encryption layer, Portability priority, Operational caveats.

13. Integrity & Resiliency Matrix
    Rows: RAW on ext4, RAW on ZFS, QCOW2 with lazy refcounts, QCOW2 with refcounts refreshed, VMDK delta chain, VHDX journaling, Ceph RBD snapshot, LVM snapshot, ZFS clone
    Columns: Corruption recovery tooling, Atomicity guarantees, Crash vulnerability surface, Snapshot rollback reliability, Validation commands, Recommended maintenance steps.

14. Distribution / Packaging Matrix
    Rows: OVA, OVF directory, BOX, XVA, RDI, ISO, DMG, WIM
    Columns: Primary purpose, Multi-VM capability, Integrity manifest support, Compression built-in, Streaming friendliness, Hypervisor neutrality, Typical internal disk format, Size overhead vs raw disk, Security signing / notarization ability.

15. Security Exposure Matrix
    Rows: Formats and layers (QCOW2, RAW, VMDK, VHDX, OVF/OVA, BOX, ISO, DMG)
    Columns: Parser attack surface (low/med/high), Embedded metadata trust concerns, Tamper detection (manifest/signature/none), Ease of secret removal, Supply chain signing options, Sandbox-first recommendation.

16. Operational Task Mapping Matrix
    Rows: Tasks (Create, Snapshot, Merge, Expand, Shrink/Reclaim, Encrypt, Convert, Integrity check, Clone)
    Columns: Per format method (command/tool), Complexity (1–5), Risk level (low/med/high), Automation friendliness, Common errors.

17. Cost (Space vs Performance) Trade-off Matrix
    Rows: Allocation modes (RAW sparse, RAW preallocated, QCOW2 default, QCOW2 compressed, VMDK thin, VMDK eagerZeroedThick, VHDX dynamic, VHDX fixed)
    Columns: Write amplification risk, Initial space footprint, Growth predictability, Latency stability, Reclamation effectiveness, Recommended workloads.

18. Forensics / Archival Suitability Matrix
    Rows: RAW, QCOW2, VMDK (snapshot chain), VHDX, ISO, DMG, WIM, OVF bundle
    Columns: Completeness of state, Ease to hash & verify, Multi-layer complexity, Tool availability long-term, Data carving ease, Preservation recommendation.

19. Multi-Tenant / Compliance Matrix
    Rows: Format + encryption layer combos
    Columns: Single artifact encryption, Key rotation process, Audit trail clarity, Backup restore simplicity, Separation of duties support, Compliance mapping (e.g., PCI, HIPAA).

20. CI/CD Build Time vs Runtime Efficiency Matrix
    Rows: Format choices for pipeline stages
    Columns: Build speed, Image size, Launch speed, Snapshot overhead, Conversion speed to production format, Reproducibility rating, Failure recovery speed.

Virtual Disk Format Feature Matrix
Portability & Interoperability Matrix
Build Pipeline Integration Matrix
