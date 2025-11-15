locals {
  # This is the name of the AMI that will be created
  name = "${local.ami.kind}-${local.ami.duo}${local.ami.eks}${local.ami.gpu}${local.ami.os}"

  # These are files that will be provisioned during the build
  temporary_cert_file   = "/tmp/combine-ca-cert.pem"
  destination_cert_file = "/etc/pki/ca-trust/source/anchors/customer-ca-chain.cert"

  key_pair_bits = {
    # Make key sizes easier to sync and compare
    rsa     = 4096
    ecdsa   = 384
    ed25519 = null
  }

  dates = {
    # make dates easier to read in tags
    lastmonth  = formatdate("YYYY-MM", timeadd(timestamp(), "-${30 * 24}h"))
    ninetydays = timeadd(timestamp(), "+${90 * 24}h")
    oneyear    = timeadd(timestamp(), "+${365 * 24}h")
    onemonth   = timeadd(timestamp(), "+${30 * 24}h")
    oneweek    = timeadd(timestamp(), "+${5 * 24}h")
    oneday     = timeadd(timestamp(), "+${1 * 24}h")
    now        = formatdate("DD-MMM-YY'T'hh:mm:ssZZZZ", timestamp())
    day        = formatdate("EEE, YYYY-MM-DD", timestamp())
    tomorrow   = formatdate("YYYY-MM-DD", timeadd(timestamp(), "+${1 * 24}h"))
    today      = formatdate("YYYY-MM-DD", timestamp())
  }

  lifecycle = {
    dev   = "oneday"
    test  = "oneweek"
    stage = "onemonth"
    prod  = "ninetydays"
  }

  aws = {
    accounts = {
      # make aws account IDs easier to read in the code
      govcloud    = "315433105135"
      prehardened = "849570812361"
    }
    cidr = {
      # make CIDRs easier to read in the code
      eng-bastion-1 = "192.133.156.218/32"
      tgw           = "100.88.160.0/19"
    }
  }

  distros = {
    # Use as a map to normalize distro names
    Ubuntu       = "Ubuntu"
    RHEL         = "RHEL"
    RedHat       = "RHEL"
    AmazonLinux  = "AmazonLinux"
    Amazon       = "AmazonLinux"
    Bottlerocket = "Bottlerocket"
    Debian       = "Debian"
    AlmaLinux    = "AlmaLinux"
  }

  ami = {
    # AMI related local values
    # Helps with
    # - Easier code review (readability)
    # - Normalization of naming conventions (centralized logic control)
    kind = contains(var.ami.features, "fedramp") || contains(var.ami.features, "fips") ? "CiscoFedRAMP" : "CiscoHardened"
    gpu  = contains(var.ami.features, "gpu") ? "GPUEnabled" : ""
    duo  = contains(var.ami.features, "duo") ? "DuoJumphost" : ""
    eks  = var.eks_version != null ? "EKS${var.eks_version}" : ""
    os   = var.ami.distro != null ? local.distros[var.ami.distro] : "AmazonLinux"
    virt = var.ami_virtualization != null ? var.ami_virtualization : "hvm"
    arch = var.ami_architecture != null ? var.ami_architecture : "x86_64"
    dev = {
      root = {
        type       = "ebs"
        iops       = null
        throughput = null
        snapshot   = null
        volume = {
          type = "gp3"
          size = "40"
        }
      }
    }
  }

  # Git information for tagging
  # NOTE: put here rather than keeping in justfile
  git_head   = trimspace(replace(file("${path.cwd}/.git/HEAD"), "ref: ", ""))
  git_config = split("\n", file("${path.cwd}/.git/config"))
  git = {
    branch = replace(local.git_head, "refs/heads/", "")
    url    = [for line in local.git_config : substr(trimspace(line), 6, -1) if strcontains(line, "url =")][0]
    hash   = file("${path.cwd}/.git/${local.git_head}")
  }

  tags = {
    # These will be applied to the AMI created
    Persistent = {
      CreatedBy   = "Packer"
      Environment = var.environment
      Name        = "MAP-${var.environment != "prod" ? var.environment : ""}-${local.name}-${formatdate("YYYY-MM-DD", timestamp())}"
      Commit      = local.git.hash
      RepoUrl     = local.git.url
      Date        = local.dates["today"]
      Day         = local.dates["day"]
      EKS         = var.eks_version != null ? var.eks_version : false
      GPU         = local.ami.gpu != "" ? true : false
      DUO         = local.ami.duo != "" ? true : false
      Distro      = local.ami.os
      FedRamp     = contains(var.ami.features, "fedramp") ? true : false
      FIPS        = contains(var.ami.features, "fips") ? true : false
      Expires     = contains(["stage", "prod"], var.environment) ? local.dates["oneyear"] : local.dates["oneweek"]
    }
    # These will only be available during build time
    Ephemeral = {
      Timestamp = local.dates["now"]
      Branch    = local.git.branch
    }
  }
}
