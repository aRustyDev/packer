# we assume that the image is being built using an AWS profile with sufficient permissions
source "amazon-ebs" "ssh" {
  communicator = "ssh"
  ssh_interface = "private_ip"

  # === === === [ Dev Workflow Controls ] === === ===
  skip_create_ami = var.environment == "dev" ? true : false

  # === === === [ AWS Account Controls ] === === ===
  region       = var.region
  profile      = var.profile
  kms_key_id   = var.kms_key_id
  encrypt_boot = var.profile != "c4p-aws-ite-no-ebs-encryption"

  vpc_filter {
    filters = {
      "tag:Name" : "${var.vpc_name}-vpc"
      "isDefault" : "false"
    }
  }

  subnet_filter {
    filters = {
      "tag:Name" : "${var.vpc_name}-tgw-attach-*",
      "state" : "available",
      "map-public-ip-on-launch" : "false",
      "map-customer-owned-ip-on-launch" : "false",
    }
    most_free = true
    random    = true
  }

  # === === === [ AMI Specifications ] === === ===
  ami_name = local.tags["Persistent"]["Name"]

  ami_virtualization_type = local.ami.virt
  instance_type           = var.instance_type
  ami_org_arns            = [var.org_arn]

  # --- --- --- [ Supports: AMI ] --- --- ---


  # --- --- --- [ Filters: AMI ] --- --- ---
  source_ami_filter {
    most_recent = true
    owners      = [local.aws.accounts["govcloud"], local.aws.accounts["prehardened"]]

    filters = {
      virtualization-type = local.ami.virt
      architecture        = local.ami.arch
      name                = "${local.name}*"
      root-device-type    = local.ami.dev.root.type
      is-public           = false
    }
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    delete_on_termination = true
    encrypted             = var.profile != "c4p-aws-ite-no-ebs-encryption"
    kms_key_id            = var.kms_key_id
    iops                  = local.ami.dev["root"].iops
    throughput            = local.ami.dev["root"].volume.type == "gp3" ? local.ami.dev["root"].throughput : null
    volume_size           = local.ami.dev["root"].volume.size
    volume_type           = local.ami.dev["root"].volume.type
    snapshot_id           = local.ami.dev["root"].snapshot
  }

  # --- --- --- [ LifeCycle: AMI ] --- --- ---
  # Lookup lifecycle timestamp based on environment
  deprecate_at = local.dates["${local.lifecycle[var.environment]}"]
  # Deregister if not prod or stage; useful for dev/test builds to avoid AMI sprawl
  force_deregister = !contains(["prod", "stage"], var.environment)
  # Only protect against deregistration in prod
  deregistration_protection {
    enabled       = var.environment == "prod"
    with_cooldown = var.environment == "prod"
  }

  # --- --- --- [ Publishing: AMI ] --- --- ---

  # === === === [ Connection Controls ] === === ===
  # --- --- --- [ Connection: AMI ] --- --- ---
  ssh_clear_authorized_keys = true
  ssh_username              = var.ssh_username
  ssh_timeout               = "5m"
  ssh_handshake_attempts    = 10

  # --- --- --- [ Connection: Bastion ] --- --- ---
  ssh_bastion_host             = var.ssh_bastion_host
  ssh_bastion_agent_auth       = var.ssh_bastion_agent_auth
  ssh_bastion_username         = var.ssh_bastion_user
  ssh_bastion_private_key_file = var.ssh_bastion_agent_auth == true ? null : var.ssh_bastion_key_file

  # === === === [ Ephemeral Resources (Packer Managed) ] === === ===
  temporary_key_pair_type               = var.key_pair_type
  temporary_key_pair_bits               = local.key_pair_bits[var.key_pair_type]
  temporary_security_group_source_cidrs = [local.aws.cidr["tgw"], local.aws.cidr["eng-bastion-1"]]

  # === === === [ Service Tunnels ] === === ===
  # --- --- --- [ Server=LocalHost && Client=AMI ] --- --- ---

  # --- --- --- [ Server=AMI && Client=LocalHost ] --- --- ---

  # === === === [ Instance Metadata Service (IMDS) Controls ] === === ===

  # === === === [ Snapshot Configs ] === === ===

  # === === === [ Spot Reservation Controls ] === === ===

  # === === === [ Tagging ] === === ===

  # Apply to the volumes that are launched to create the AMI
  # NOT applied to the resulting AMI unless duplicated in 'tags'
  run_volume_tags = merge(
    var.tags,
    local.tags["Persistent"],
    local.tags["Ephemeral"],
    {
      SafeToDestroy = "false"
    },
    {
      Name = "${local.tags["Persistent"]["Name"]}-run-volume"
    }
  )


  # Apply to the generated resources, launched to create the EBS volumes.
  # ie: key-pair, security group, iam profile and role, snapshot, network interfaces and instance
  # NOTE: by default, the resulting AMI inherits these tags
  run_tags = merge(
    var.tags,
    local.tags["Persistent"],
    local.tags["Ephemeral"],
    {
      SafeToDestroy = "false"
    }
  )
  # Don't propagate the "run_tags" to the resulting AMI?
  skip_ami_run_tags = true

  tags = merge(
    var.tags,
    local.tags["Persistent"]
  )
}
