##
# Output variables here
##

output "acm_domains" {
  value = aws_acm_certificate.external
}

output "oracle_db_server_names" {
  value = local.oracle_db_server_names
}

output "delius_core_application_passwords_secret_arn" {
  value = aws_secretsmanager_secret.delius_core_application_passwords_secret.arn
}