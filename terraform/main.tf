locals {
  ansible_inventory_abs = abspath("${path.root}/${var.ansible_inventory_path}")
  ansible_deploy_playbook_abs = abspath("${path.root}/${var.ansible_playbook_deploy}")
  ansible_destroy_playbook_abs = abspath("${path.root}/${var.ansible_playbook_destroy}")
  vault_password_abs = abspath("${path.root}/${var.vault_password_file}")
  ansible_requirements_abs = abspath("${path.root}/../ansible/requirements.yml")
  # Important: Terraform Cloud execution may run with an empty/missing `ansible/`
  # directory available during `plan`. To keep `plan` working, we hash only paths
  # (not file contents).
  config_hash = sha256(join("\n", [
    local.ansible_inventory_abs,
    local.ansible_deploy_playbook_abs,
    local.ansible_destroy_playbook_abs,
    local.vault_password_abs,
  ]))
}

resource "null_resource" "deploy" {
  triggers = {
    config_hash = local.config_hash
    ansible_requirements_abs = local.ansible_requirements_abs
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command = <<-EOT
      set -euo pipefail

      export ANSIBLE_FORCE_COLOR=true

      # Ensure Ansible collection modules are present (needed for community.docker).
      ansible-galaxy collection install -r "${self.triggers.ansible_requirements_abs}" --force-with-deps

      ansible-playbook \
        -i "${local.ansible_inventory_abs}" \
        "${local.ansible_deploy_playbook_abs}" \
        --vault-password-file "${local.vault_password_abs}"
    EOT
  }
}

resource "null_resource" "destroy" {
  triggers = {
    config_hash = local.config_hash
    ansible_inventory_abs = local.ansible_inventory_abs
    ansible_destroy_playbook_abs = local.ansible_destroy_playbook_abs
    vault_password_abs = local.vault_password_abs
    ansible_requirements_abs = local.ansible_requirements_abs
  }

  # Runs only on `terraform destroy`.
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-lc"]
    command = <<-EOT
      set -euo pipefail

      ansible-galaxy collection install -r "${lookup(self.triggers, "ansible_requirements_abs", "${path.root}/../ansible/requirements.yml")}" --force-with-deps || true

      # Skip cleanup if old state points to an obsolete path.
      if [ -f "${self.triggers.ansible_destroy_playbook_abs}" ] && [ -f "${self.triggers.ansible_inventory_abs}" ]; then
        ansible-playbook \
          -i "${self.triggers.ansible_inventory_abs}" \
          "${self.triggers.ansible_destroy_playbook_abs}" \
          --vault-password-file "${self.triggers.vault_password_abs}"
      else
        echo "Destroy playbook path not found in previous state, skipping cleanup run."
      fi
    EOT
  }
}

