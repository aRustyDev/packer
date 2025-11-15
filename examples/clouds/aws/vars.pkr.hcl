# TODO: get description of what this is for
variable "ca_cert_path" {
  type = string

  validation {
    condition     = length(regexall("^.+\\.(cer|crt|pem)$", var.ca_cert_path)) > 0
    error_message = "Must end with .cer, .crt, or .pem."
  }
}

variable "profile" {
  type    = string
  default = "c4p-aws-ite-devops-admin"

  validation {
    condition     = length(regexall("^[A-Za-z0-9_-]{3,}$", var.profile)) > 0
    error_message = "Must be alphanumeric/underscore/hyphen and at least 3 chars."
  }
}

variable "region" {
  type    = string
  default = "us-east-1"

  validation {
    condition     = length(regexall("^[a-z]{2}-[a-z0-9-]+-\\d+$", var.region)) > 0
    error_message = "Must match AWS region pattern (e.g. us-east-1)."
  }
}

variable "emulated_region" {
  type    = string
  default = "us-isob-east-1"

  validation {
    condition     = length(regexall("^[a-z]{2}-[a-z0-9-]+-\\d+$", var.emulated_region)) > 0
    error_message = "Must follow AWS region pattern (e.g. us-east-1 or us-isob-east-1)."
  }
}

variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod", "test"], var.environment)
    error_message = "Must be one of: [dev, stage, prod, or test]."
  }
}

variable "org_arn" {
  type = string
}

variable "kms_key_id" {
  type = string

  validation {
    condition     = length(var.kms_key_id) == 0 || length(regexall("^(arn:aws:kms:[a-z0-9-]+:\\d{12}:key/[0-9a-fA-F-]{36}|[0-9a-fA-F-]{36})$", var.kms_key_id)) > 0
    error_message = "Must be a 36-char UUID or a full KMS key ARN."
  }
}

variable "eks_version" {
  type        = string
  description = "The major.minor version of EKS to use in the build."
  default     = null

  validation {
    condition     = var.eks_version == null || can(contains([for i in range(31, 34) : format("1.%02d", i)], var.eks_version))
    error_message = "We only support [ 1.31 | 1.32 | 1.33 ] EKS releases."
  }
}

variable "instance_type" {
  type    = string
  default = "t3.micro"

  validation {
    condition     = length(regexall("^[a-z0-9]+\\.[a-z0-9]+$", var.instance_type)) > 0
    error_message = "Must be in form family.size (e.g. t3.micro)."
  }
}

variable "ami_virtualization" {
  type        = string
  description = "The type of virtualization of the AMI to build."
  default     = "hvm"

  validation {
    condition     = contains(["hvm"], var.ami_virtualization)
    error_message = "We only support [ hvm ] virtualization."
  }
}

variable "ami_architecture" {
  type        = string
  description = "The type of architecture of the AMI to build."
  default     = "x86_64"

  validation {
    condition     = contains(["arm64", "x86_64"], var.ami_architecture)
    error_message = "We only support [ arm64 | x86_64 ] architectures."
  }
}

variable "ami" {
  type = object({
    distro   = string
    features = list(string)
  })
  description = "Target Distro and Features of source AMI."
  default = {
    distro   = "AmazonLinux"
    features = []
  }

  validation {
    condition     = contains(["fips", "fedramp", "duo", "gpu"], var.ami.features) || length(var.ami.features) == 0
    error_message = "We only support [ fips | fedramp | duo ] as features."
  }

  validation {
    condition     = contains(["fips"], var.ami.features) ? var.ami.distro == "Bottlerocket" : true
    error_message = "FIPS is only available on the Bottlerocket distro."
  }

  validation {
    condition     = contains(["gpu"], var.ami.features) ? var.ami.distro == "Bottlerocket" : true
    error_message = "GPU is only available on the Bottlerocket distro."
  }

  validation {
    condition     = contains(["duo"], var.ami.features) ? contains(["AlmaLinux"], var.ami.distro) : true
    error_message = "DUO is only available on the AlmaLinux distro."
  }

  validation {
    condition     = contains(["Ubuntu", "RHEL", "RedHat", "AmazonLinux", "Amazon", "Bottlerocket", "Debian", "AlmaLinux"], var.ami.distro)
    error_message = "We only support [ Ubuntu | RHEL | RedHat | AmazonLinux | Amazon | Bottlerocket | Debian | AlmaLinux ] as distros."
  }
}

variable "vpc_name" {
  type        = string
  description = "Short name of the VPC to deploy too."
  default     = "ite-devops"
}

variable "key_pair_type" {
  type        = string
  description = "The type of temporary ssh key packer creates. Only supports for [ ecdsa | rsa | ed25519 ]."
  default     = "rsa"

  validation {
    condition     = contains(["ecdsa", "rsa", "ed25519"], var.key_pair_type)
    error_message = "We only support [ ecdsa | rsa | ed25519 ] key types."
  }
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"

  validation {
    condition     = length(regexall("^[a-z_][a-z0-9_-]*$", var.ssh_username)) > 0
    error_message = "Must start with a letter/underscore and contain only lowercase, digits, _ or -."
  }
}

variable "ssh_bastion_host" {
  type        = string
  description = "(Required) the bastion hostname."
  default     = "eng-bastion-1.devops.map.cisco"
}

variable "ssh_bastion_user" {
  type        = string
  description = "(Required) username of account that can access the bastion."
}

variable "ssh_bastion_agent_auth" {
  type        = bool
  description = "Optional name of existing SSH Key Pair in AWS."
  default     = true
}

variable "ssh_bastion_key_file" {
  type        = string
  description = "Optional name of existing SSH Key Pair in AWS."
  default     = null
}

variable "tags" {
  type = map(string)

  validation {
    condition = length(var.tags) == 0 || alltrue([
      for k, v in var.tags :
      length(regexall("^[A-Za-z0-9_.:-]{1,128}$", k)) > 0 &&
      length(v) <= 256
    ])
    error_message = "All tag keys must match ^[A-Za-z0-9_.:-]{1,128}$ and values <= 256 chars."
  }
}
