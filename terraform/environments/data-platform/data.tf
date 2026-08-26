data "aws_secretsmanager_secret_version" "cloud_platform_live" {
  secret_id = module.cloud_platform_live_secret.secret_id
}

data "aws_secretsmanager_secret_version" "justiceuk_entra" {
  secret_id = module.justiceuk_entra_secret.secret_id
}
