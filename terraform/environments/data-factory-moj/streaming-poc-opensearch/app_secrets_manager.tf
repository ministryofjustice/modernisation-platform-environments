resource "random_string" "master_username" {
  count   = contains(["development"], local.environment) ? 1 : 0
  length  = 16
  special = false
}

resource "random_password" "master_password" {
  count            = contains(["development"], local.environment) ? 1 : 0
  length           = 32
  special          = true
  override_special = "!#$%^&*"
}

resource "aws_secretsmanager_secret" "opensearch_credentials" {
  count = contains(["development"], local.environment) ? 1 : 0
  name  = "${local.cluster_name}/master-credentials"
}

resource "aws_secretsmanager_secret_version" "opensearch_credentials" {
  count     = contains(["development"], local.environment) ? 1 : 0
  secret_id = aws_secretsmanager_secret.opensearch_credentials[0].id
  secret_string = jsonencode({
    username = random_string.master_username[0].result
    password = random_password.master_password[0].result
  })
}
