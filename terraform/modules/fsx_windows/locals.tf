locals {
  # expecting the secret to be json key/pair with username as key, e.g. `{"svc_join_domain":"mypassword"}`
  domain_join_secret_string = var.self_managed_active_directory != null ? data.aws_secretsmanager_secret_version.this[0].secret_string : null
  domain_join_secret_json   = var.self_managed_active_directory != null ? jsondecode(local.domain_join_secret_string) : null
  domain_join_password      = var.self_managed_active_directory != null ? local.domain_join_secret_json[var.self_managed_active_directory.username] : null
}
