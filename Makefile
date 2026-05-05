TF_DIR=terraform
ANSIBLE_DIR=ansible

.PHONY: tf-init tf-fmt tf-validate tf-plan tf-apply tf-destroy ansible-deps ansible-prepare ansible-deploy

tf-init:
	terraform -chdir=$(TF_DIR) init

tf-fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

tf-validate: tf-init
	terraform -chdir=$(TF_DIR) validate

tf-plan:
	terraform -chdir=$(TF_DIR) plan

tf-apply:
	terraform -chdir=$(TF_DIR) apply -auto-approve

tf-destroy:
	terraform -chdir=$(TF_DIR) destroy -auto-approve

ansible-deps:
	ansible-galaxy collection install -r $(ANSIBLE_DIR)/requirements.yml

ansible-prepare:
	ansible-playbook -i $(ANSIBLE_DIR)/inventory.ini $(ANSIBLE_DIR)/playbook.yml --tags prepare --vault-password-file .vault_pass

ansible-deploy:
	ansible-playbook -i $(ANSIBLE_DIR)/inventory.ini $(ANSIBLE_DIR)/playbook.yml --tags deploy --vault-password-file .vault_pass
