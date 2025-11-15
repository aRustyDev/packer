data "amazon-ami" "cloud9" {
  region      = var.region
  profile     = var.profile
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
