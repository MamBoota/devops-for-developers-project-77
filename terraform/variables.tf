variable "ansible_inventory_path" {
  description = "Path to Ansible inventory file"
  type        = string
  default     = "../ansible/inventory.ini"
}

variable "ansible_playbook_deploy" {
  description = "Playbook that configures application + DB + LB + monitoring"
  type        = string
  default     = "../ansible/site.yml"
}

variable "ansible_playbook_destroy" {
  description = "Playbook that tears down application + DB + LB + monitoring"
  type        = string
  default     = "../ansible/destroy.yml"
}

variable "vault_password_file" {
  description = "Ansible Vault password file (local, not committed)"
  type        = string
  default     = "../.vault_pass"
  sensitive   = true
}
