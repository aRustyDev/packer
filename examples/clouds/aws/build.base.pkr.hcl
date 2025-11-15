build {
  name = "base"

  sources = [
    "source.amazon-ebs.ssh"
  ]

  provisioner "file" {
    source      = var.ca_cert_path
    destination = local.temporary_cert_file
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
