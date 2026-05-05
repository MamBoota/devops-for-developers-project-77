variable "ansible_inventory_path" {
  description = "Path to Ansible inventory file"
  type        = string
  default     = "../ansible/inventory.ini"
}

variable "ansible_playbook_deploy" {
  description = "Playbook that configures application + DB + LB + monitoring"
  type        = string
  default     = "../ansible/playbook.yml"
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

variable "redmine_domain" {
  description = "Application domain name pointed to load balancer"
  type        = string
  default     = "example.com"
}

variable "load_balancer_ip" {
  description = "Load balancer public/local IP used in domain A-record"
  type        = string
  default     = "192.168.2.5"
}
