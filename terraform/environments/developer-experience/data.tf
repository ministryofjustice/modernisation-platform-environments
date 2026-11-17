data "aws_secretsmanager_secret_version" "cloud_platform_live_1" {
  secret_id = module.cloud_platform_live_1_secret.secret_id
}
