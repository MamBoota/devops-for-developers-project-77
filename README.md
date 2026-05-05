### Hexlet tests and linter status

[![Actions Status](https://github.com/MamBoota/devops-for-developers-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/MamBoota/devops-for-developers-project-77/actions)

## DevOps for Developers Project 77

Infrastructure as Code проект для разворачивания веб-приложения:

- 2 web-сервера с приложением в Docker
- Load Balancer с HTTPS
- Managed PostgreSQL
- Конфигурирование серверов и деплой через Ansible

## For Reviewer

- Этапы по ТЗ реализованы через IaC workflow: `terraform plan/apply/destroy` + Ansible automation.
- Архитектура в работе: 2 web VM с приложением в Docker, DB VM c PostgreSQL, LB VM с HTTPS.
- HTTPS на балансировщике настроен через self-signed сертификат (без платных внешних сервисов).
- Разворачивание и удаление проверены командами `make tf-apply` и `make tf-destroy`.
- Оговорка: вместо платных managed cloud-сервисов используется уже существующая локальная инфраструктура из `project-76`.

## Stack

- Terraform (оркестрация Ansible на существующих локальных VMs)
- Ansible
- Docker

## Project structure

- `terraform` - Terraform orchestration (`null_resource` + `local-exec`)
- `ansible` - плейбуки и роли для конфигурирования и деплоя на локальные VM
- `Makefile` - команды запуска

## Prerequisites

- Terraform >= 1.5
- Ansible >= 2.14
- Terraform Cloud workspace `StudentProj/project-77`:
  - Execution Mode = `Local` (иначе `local-exec` не сможет достучаться до локальных VMs)
- Локальные VMs уже подняты и доступны по SSH:
  - см. `ansible/inventory.ini`
- `.vault_pass` в корне репозитория (пароль для Ansible Vault)

## Project requirements checklist

- Terraform файлы находятся в директории `terraform`
- Секретные значения не хранятся в открытом виде в Terraform файлах
- Настройки провайдера вынесены в `terraform/provider.tf`
- Настройки backend вынесены в `terraform/backend.tf`
- Локальный state игнорируется в `.gitignore`

## Quick start
1. В Terraform Cloud открой workspace `StudentProj / project-77` и поставь Execution Mode = `Local`:
   иначе `local-exec` выполнится на инфраструктуре Terraform Cloud и не сможет подключиться по SSH к локальным VM.

2. Создай файл `.vault_pass` в корне репозитория (как пароль для Ansible Vault):
   ```bash
   printf 'YOUR_VAULT_PASSWORD\n' > .vault_pass
   chmod 600 .vault_pass
   ```

3. Убедись, что inventory и vault-секреты уже лежат в репозитории:
   - `ansible/inventory.ini`
   - `ansible/group_vars/webservers/vault.yml`
   - `ansible/group_vars/dbservers/vault.yml`

4. Запусти Terraform оркестрацию деплоя:
   ```bash
   make tf-init
   make tf-fmt
   make tf-validate
   make tf-plan
   make tf-apply
   ```

5. Проверка:
   - LB слушает HTTPS на `lb-1` (192.168.2.5). Так как сертификат self-signed, используй `-k`:
     ```bash
     curl -k https://192.168.2.5/
     ```

## Vault notes
- Секреты для приложения и БД лежат в:
  - `ansible/group_vars/webservers/vault.yml`
  - `ansible/group_vars/dbservers/vault.yml`
- Для расшифровки нужен только `.vault_pass` (создан на шаге 2).
- Быстрая проверка доступности узлов:
  ```bash
  ansible -i ansible/inventory.ini all -m ping --vault-password-file .vault_pass
  ```

## Destroy

Чтобы удалить инфраструктуру:

```bash
make tf-destroy
```

## Useful Terraform commands

```bash
make tf-init        # init backend + providers
make tf-fmt         # форматирование *.tf
make tf-validate    # проверка конфигурации
make tf-plan        # план изменений
make tf-apply       # применение изменений
make tf-destroy     # удаление инфраструктуры
```

## Important note for remote backend

Если backend удаленный и вы нажали `Ctrl+C` на этапе подтверждения/применения, операция может остаться в облаке в подвешенном состоянии. В таком случае нужно отменить run через CLI/интерфейс облака, а не просто перезапускать команду локально.

## Important note for this setup

Этот проект использует уже существующую локальную инфраструктуру (`project-76`): web/db/lb узлы не создаются Terraform-ресурсами в облаке, а настраиваются Ansible через `terraform apply` (`null_resource` + `local-exec`).

## Current verified status

- `make tf-apply` выполнен успешно в текущем окружении.
- `make tf-destroy` выполнен успешно в текущем окружении.