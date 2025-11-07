# AMI (Amazon Machine Image)

- AMI: Cloud image abstraction referencing underlying snapshot(s).
- **AMI** (Amazon Machine Image):
  - EBS-backed: References one (or more) EBS snapshot(s) (which themselves store raw blocks).
  - Instance-store (deprecated pattern): S3 bundle (historically a manifest + parts, often raw).
  - Older artifacts: AKI (kernel), ARI (ramdisk) in paravirtual era.
