### Hexlet tests and linter status

[![Actions Status](https://github.com/MamBoota/devops-for-developers-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/MamBoota/devops-for-developers-project-77/actions)

## DevOps for Developers Project 77

Infrastructure as Code проект для разворачивания веб-приложения:

- 2 web-сервера с приложением в Docker
- Load Balancer (Nginx) в локальной сети — **HTTP**, как в **project-76**
- Публичный **HTTPS** на **VPS** + **reverse SSH tunnel** на локальный `lb-1:80`
- PostgreSQL (локальный VM)
- Ansible + Terraform (Terraform Cloud, Datadog monitor)

## For Reviewer

- Этапы по ТЗ: `terraform plan/apply/destroy` + Ansible.
- Плейбук: `ansible/playbook.yml`.
- Стек: 2 web VM (`mamboota/devops-for-developers-project-74:latest`), DB PostgreSQL, **lb-1** с Nginx **без TLS** (прокси на приложения по HTTP).
- **Публикация в интернет** — как в **project-76**: домен → **VPS** (HTTPS), на VPS `proxy_pass` на `127.0.0.1:18080`; **`make start`** поднимает Ansible и **reverse SSH** на локальный `lb-1:80`.
- В Terraform **`load_balancer_ip`** — **публичный IP VPS** (A-запись), не LAN lb-1.
- Мониторинг: Datadog (Ansible + Terraform). **`make start`** = деплой + туннель; **`make stop`** = остановка туннеля + **`terraform destroy`**.

## Stack

- Terraform (remote state, DNS check, Datadog)
- Ansible
- Docker
- VPS с публичным IP (relay), по желанию Let’s Encrypt на VPS

## Project structure

- `terraform` — orchestration (`null_resource` + `local-exec`)
- `ansible` — плейбуки и роли
- `docs/vps-relay-nginx.conf.example` — пример `server { }` для Nginx на VPS
- `Makefile` — деплой, relay, тесты

## Prerequisites

- Terraform >= 1.5, Ansible >= 2.14
- **VPN** при необходимости для Terraform Cloud / registry (`make test`, `make tf-apply`, **`make stop`**)
- Workspace Terraform Cloud `StudentProj/project-77`, **Execution Mode = Local**
- Локальные VM по `ansible/inventory.ini`, SSH-ключ (см. inventory)
- **VPS**: Ubuntu, root по SSH с твоей машины, установлен Nginx, настроен vhost по примеру в `docs/` (порт бэкенда **`127.0.0.1:18080`**)
- `.vault_pass` в корне репозитория

## Публичный доступ (как в project-76)

1. На **VPS** включи сайт с TLS (например Let’s Encrypt) и `proxy_pass http://127.0.0.1:18080;` — см. **`docs/vps-relay-nginx.conf.example`**.
2. **A-запись** домена → **публичный IP VPS** (этот же IP укажи в **`load_balancer_ip`** в `terraform.tfvars`).
3. Локально одной командой: **`make start`** (Ansible + reverse SSH на VPS).
4. Проверка: `curl -I https://<домен>/`

Переопределение без правки Makefile: `make start VPS_USER=ubuntu VPS_IP=1.2.3.4` (см. переменные в начале `Makefile`).

## Две основные команды

| Команда | Что делает |
|--------|------------|
| **`make start`** | Коллекции Ansible → плейбук **`prepare,deploy,monitoring`** → **туннель на VPS** (сайт снаружи начинает ходить на локальный LB). |
| **`make stop`** | **Останавливает туннель**, затем **`terraform destroy`** (в т.ч. Ansible destroy из Terraform). Нужен VPN, если без него недоступен Terraform Cloud. |

Остальное (по необходимости):

- **`make test`** — проверки курса: Terraform validate, Ansible, HTTP по домену (сайт должен уже отвечать после `make start`).
- **`make relay-up` / `make relay-stop` / `make relay-status` / `make relay-logs`** — только туннель (если деплой уже делал отдельно).
- **`make tf-apply`** — state, DNS-check, Datadog monitor (секреты в `terraform/secrets.auto.tfvars`).

Шаблоны: `terraform/terraform.tfvars.example`, `terraform/secrets.auto.tfvars.example`.

## Первый запуск (кратко)

1. Terraform Cloud: workspace **Local**.
2. `.vault_pass`, vault в `ansible/group_vars/`.
3. VPS: Nginx по **`docs/vps-relay-nginx.conf.example`**, certbot.
4. **`terraform.tfvars`**: домен и **`load_balancer_ip` = IP VPS**; при работе с Datadog в Terraform — `secrets.auto.tfvars`.
5. **`make tf-init`** (с VPN, один раз), при необходимости **`make tf-apply`**.
6. **`make start`** — дальше правки приложения снова **`make start`**.

## Domain setup и Terraform

- DNS: **домен → VPS**, не на приватный Multipass.
- В `terraform.tfvars` тот же публичный IP, что в A-записи.
- `terraform output application_url` — `https://<домен>/`.

## Monitoring

- Vault: `vault_datadog_api_key` в `ansible/group_vars/webservers/vault.yml`.
- `make start` / `make ansible-monitoring`.
- Monitor в Datadog: `secrets.auto.tfvars` + `make tf-apply`.

## Остановка

```bash
make stop
```

## Команды Terraform / Ansible

```bash
make tf-init make tf-validate make tf-plan make tf-apply make tf-destroy
make ansible-deps make ansible-prepare make ansible-deploy make ansible-monitoring
```

## VPN и Terraform

Backend — Terraform Cloud, провайдеры — **registry.terraform.io**. Для стабильной работы **`make tf-init` / `make test` / `make tf-apply` / `make stop`** используй VPN, если без него эти хосты из твоей сети недоступны. В `Makefile` у **`tf-init`** до трёх попыток и кэш `~/.terraform.d/plugin-cache`.

## Important note for remote backend

Если прервал `apply`/`destroy`, проверь незавершённые run в Terraform Cloud.

## Important note for this setup

Локальная инфраструктура из **project-76**; публичная выдача — **relay на VPS**, как в **project-76**, а не self-signed HTTPS на Multipass-LB.
