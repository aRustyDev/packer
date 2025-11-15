# TODOs

## data.pkr.hcl

### `data.amazon-ami.cloud9`

- [ ] Include `sriov-net-support`?
- [ ] Include `ena-support`?
- [ ] Include `hypervisor`?

## locals.pkr.hcl

### `local.temporary_cert_file` && `local.destination_cert_file`

- these will need to move to ansible role controls later

## plugins.pkr.hcl

- [ ] Tighten scope on plugin versions

## source.amzn.ebs.ssh.pkr.hcl

### `source.amzn.ebs.ssh`

#### Vault

- Setup `vault_aws_engine`

#### SSH Controls

- `pause_before_connecting`
- `ssh_file_transfer_method`
- `ssh_keep_alive_interval`
- `ssh_read_write_timeout`
  - value = `null` (Useful if a process on the remote will hang when finished)

#### Dev Workflow Controls

- `skip_save_build_region`

#### AMI Specifications

- `ami_description`: Figure out how to pass a dynamic description through here

##### AMI Specifications (Supports)

- [ ] sriov_support
- [ ] ena_support
- [ ] ebs_optimized
- [ ] enable_nitro_enclave
- [ ] enable_unlimited_credits

##### AMI Specifications (Filters)

- [ ] Include `sriov-net-support`?
- [ ] Include `ena-support`?
- [ ] Include `hypervisor`?

##### AMI Specifications (`launch_block_device_mappings`)

- [ ] Verify these for sanity

##### AMI Specifications (`ami_block_device_mappings`)

- [ ] Figure out how to pass these through sanely
  - NOTE: Not sure how I want to try and implement this?
  - May end up needing to pass a variablized file name through to manage stuff like this?
- [ ] Decide if this will be supported

##### AMI Specifications (LifeCycle)

##### AMI Specifications (Publishing)

- [ ] `region_kms_key_ids`
- [ ] `ami_regions`
- [ ] `ami_product_codes`
- [ ] `ami_ou_arns`
- [ ] `ami_org_arns`
- [ ] `ami_groups`
- [ ] `ami_users`

#### Connection Controls

##### Connection Controls (AMI)

##### Connection Controls (Bastion)

#### Ephemeral Resources

#### Service Tunnels

##### Service Tunnels (Local->Remote)

- [ ] `ssh_remote_tunnels`

##### Service Tunnels (Remote->Local)

- [ ] `ssh_local_tunnels`

#### Instance Metadata Service Controls

- [ ] `imds_support`
- [ ] `metadata_options`
  - [ ] `http_endpoint`
  - [ ] `http_tokens`
  - [ ] `http_put_response_hop_limit`
  - [ ] `instance_metadata_tags`

#### Snapshot Controls

- [ ] `snapshot_copy_duration_minutes`
- [ ] `snapshot_groups`
- [ ] `snapshot_users`
- [ ] `force_delete_snapshot`

#### Spot Reservation Controls

- [ ] `block_duration_minutes`
- [ ] `spot_allocation_strategy`
- [ ] `spot_instance_types`
- [ ] `spot_price`

#### Tagging

- [ ] `snapshot_tags`
- [ ] `spot_tags`
