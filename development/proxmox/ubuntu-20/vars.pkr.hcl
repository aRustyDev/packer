variable "pm_user" {
  type        = string
  description = "Proxmox User Name"
  default     = "packer"
}
variable "pm_pass" {
  type        = string
  description = "Proxmox User Password"
  default     = "packer"
}
variable "pm_token" {
  type        = string
  description = "Proxmox API Token"
}
variable "ssh_user" {
  type        = string
  description = "SSH User"
  default     = "packer"
}
variable "ssh_pass" {
  type        = string
  description = "SSH Password"
  default     = "packer"
}