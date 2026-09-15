resource "random_password" "litellm_master_key" {
  length  = 48
  special = false
}

# Encrypts provider credentials stored in the database; changing it makes existing encrypted values unreadable
resource "random_password" "litellm_salt_key" {
  length  = 48
  special = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "random_password" "litellm_db" {
  length  = 40
  special = false
}

resource "aws_secretsmanager_secret" "litellm_db_password" {
  #checkov:skip=CKV_AWS_149: "Encrypted with the AWS managed key"
  #checkov:skip=CKV2_AWS_57: "Rotation is manual, ECS tasks only read the password at start"
  name                    = "litellm-gateway/db-password"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "litellm_db_password" {
  secret_id     = aws_secretsmanager_secret.litellm_db_password.id
  secret_string = random_password.litellm_db.result
}

resource "aws_secretsmanager_secret" "litellm_master_key" {
  #checkov:skip=CKV_AWS_149: "Encrypted with the AWS managed key"
  #checkov:skip=CKV2_AWS_57: "Rotation is manual, rotating invalidates admin access until tasks restart"
  name                    = "litellm-gateway/master-key"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "litellm_master_key" {
  secret_id     = aws_secretsmanager_secret.litellm_master_key.id
  secret_string = "sk-${random_password.litellm_master_key.result}"
}

resource "aws_secretsmanager_secret" "litellm_salt_key" {
  #checkov:skip=CKV_AWS_149: "Encrypted with the AWS managed key"
  #checkov:skip=CKV2_AWS_57: "Salt key must never be rotated"
  name                    = "litellm-gateway/salt-key"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "litellm_salt_key" {
  secret_id     = aws_secretsmanager_secret.litellm_salt_key.id
  secret_string = "sk-${random_password.litellm_salt_key.result}"
}
