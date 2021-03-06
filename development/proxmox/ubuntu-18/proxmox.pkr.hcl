packer {
  required_plugins {
    proxmox = {
      version = " >= 1.0.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "proxmox-ubuntu-18" {
  proxmox_url      = "https://192.168.0.42:8006/api2/json"
  vm_name          = "packer-ubuntu-18"
  iso_url          = "http://192.168.0.144/ubuntu-18.04.6-live-server-amd64.iso"
  iso_checksum     = "6c647b1ab4318e8c560d5748f908e108be654bad1e165f7cf4f3c1fc43995934"
  username         = "${var.pm_user}"
  password         = "${var.pm_pass}"
  token            = "${var.pm_token}"
  node             = "proxmox"
  iso_storage_pool = "local"

  ssh_username           = "${var.ssh_user}"
  ssh_password           = "${var.ssh_pass}"
  ssh_timeout            = "24h"
  ssh_pty                = true
  ssh_handshake_attempts = 18

  boot_wait = "5s"
  # http_directory = "http" # Starts a local http server, serves Preseed file
  boot_command = [
    "<esc><wait><esc><wait><f6><wait><esc><wait>",
    "<bs><bs><bs><bs><bs>",
    "ip=${cidrhost("192.168.0.0/24", 9)}::${cidrhost("192.168.0.0/24", 1)}:${cidrnetmask("192.168.0.0/24")}::::${cidrhost("192.168.0.0/24", 1)} ",
    # " autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/http/ ", #Dont specify the file
    " autoinstall ds=nocloud-net;s=http://192.168.0.144:80/preseed/ubuntu-18/ ", #Dont specify the file
    "boot",
    "--- <enter>"
  ]

  insecure_skip_tls_verify = true

  template_name        = "packer-ubuntu-18"
  template_description = "packer generated ubuntu-18.04.6-server-amd64"
  unmount_iso          = true

  pool       = "packer"
  memory     = 4096
  cores      = 1
  sockets    = 1
  os         = "l26"
  qemu_agent = true
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
  }
}

build {
  sources = ["source.proxmox-iso.proxmox-ubuntu-18"]
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "ls /"
    ]
  }
}