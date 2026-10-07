output "portal_url" { value = local.portal_url }
output "webhook_secret_names" {
  value = { for id, secret in aws_secretsmanager_secret.webhook : id => secret.name }
}
