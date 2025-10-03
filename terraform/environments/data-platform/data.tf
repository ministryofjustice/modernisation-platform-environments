data "aws_secretsmanager_secret_version" "cloud_platform_live" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  secret_id = module.cloud_platform_live_secret[0].secret_id
}
