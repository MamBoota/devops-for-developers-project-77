output "deploy_trigger_hash" {
  description = "Hash of inputs that triggers ansible deploy"
  value       = local.config_hash
  sensitive   = true
}

