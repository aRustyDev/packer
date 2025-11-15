build {
  name = "eks"

  sources = [
    "source.amazon-ebs.ssh"
  ]

  provisioner "file" {
    source      = var.ca_cert_path
    destination = local.temporary_cert_file
  }

  provisioner "shell" {
    # we set the execute command explicitly because the Cloud9 images mount /tmp with `noexec` and it can't be run using
    # the normal shebang way
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    inline = [
      "set -x",
      "sudo mv ${local.temporary_cert_file} ${local.destination_cert_file}",
      "sudo update-ca-trust extract",
      #"echo AWS_REGION=${var.emulated_region} | sudo tee -a /etc/eks/kubelet/environment",
      #"echo AWS_DEFAULT_REGION=${var.emulated_region} | sudo tee -a /etc/eks/kubelet/environment",
      "sudo sed -i 's#ExecStart=/usr/bin/nodeadm#ExecStart=/usr/bin/env AWS_REGION=${var.emulated_region} /usr/bin/nodeadm#' /etc/systemd/system/nodeadm-config.service",
      "sudo sed -i 's#ExecStart=/usr/bin/nodeadm#ExecStart=/usr/bin/env AWS_REGION=${var.emulated_region} /usr/bin/nodeadm#' /etc/systemd/system/nodeadm-run.service",
      "sudo sed -i 's#ExecStart=/usr/bin/kubelet#ExecStart=/usr/bin/env AWS_REGION=${var.emulated_region} /usr/bin/kubelet#' /etc/systemd/system/kubelet.service",
    ]
  }
}

# build {
#   sources = ["source.amazon-ebs.this"]

#   provisioner "ansible" {
#     playbook_file = "${var.pwd}/ansible/playbooks/common_packages.yml"
#     extra_arguments = [
#       "--ssh-extra-args='-o StrictHostKeyChecking=no'"
#     ]
#     # Removed environment_vars (unsupported in current plugin)
#     execute_command = "ANSIBLE_ROLES_PATH='${var.pwd}/ansible/roles' ansible-playbook -i {{.InventoryFile}} {{.PlaybookFile}}"
#   }
# }
