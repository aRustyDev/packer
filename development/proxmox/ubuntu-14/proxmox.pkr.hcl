packer {
  required_plugins {
    proxmox = {
      version = " >= 1.0.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "proxmox-ubuntu-14" {
  proxmox_url      = "https://192.168.0.42:8006/api2/json"
  vm_name          = "${var.vm_name}"
  iso_url          = "http://192.168.0.144/ubuntu-14.04.1-server-amd64.iso"
  iso_checksum     = "946a6077af6f5f95a51f82fdc44051c7aa19f9cfc5f737954845a6050543d7c2"
  username         = "${var.pm_user}"
  password         = "${var.pm_pass}"
  token            = "${var.pm_token}"
  node             = "proxmox"
  iso_storage_pool = "local"

  ssh_username           = "${var.ssh_user}"
  ssh_password           = "${var.ssh_pass}"
  ssh_timeout            = "20m"
  ssh_pty                = true
  ssh_handshake_attempts = 20

  boot_wait      = "5s"
  http_directory = "http" # Starts a local http server, serves Preseed file
  boot_command = [
    "<esc><wait>",
    "<esc><wait>",
    "<enter><wait>",
    "/install/vmlinuz<wait>",
    " initrd=/install/initrd.gz",
    " auto-install/enable=true",
    " debconf/priority=critical",
    " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed_14.04.cfg<wait>",
    " -- <wait>",
    "<enter><wait>"
  ]

  insecure_skip_tls_verify = true

  template_name        = "${var.vm_name}"
  template_description = "packer generated ubuntu-14.04.1-server-amd64"
  unmount_iso          = true

  pool       = "packer"
  memory     = 4096
  cores      = 1
  sockets    = 1
  os         = "l26"
  qemu_agent = true
  cloud_init = true
  # scsi_controller = "virtio-scsi-pci"
  disks {
    type              = "scsi"
    disk_size         = "30G"
    storage_pool      = "local-lvm"
    storage_pool_type = "lvm"
    format            = "raw"
  }
  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = true
    vlan_tag = 1
  }
}

build {
  sources = ["source.proxmox-iso.proxmox-ubuntu-14"]
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "ls /"
    ]
  }
}