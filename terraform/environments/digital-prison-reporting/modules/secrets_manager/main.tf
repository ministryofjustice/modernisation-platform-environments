resource "random_password" "random_string" {
  count            = var.generate_random ? 1 : 0  
  length           = var.length
  lower            = var.use_lower
  numeric          = var.use_number
  min_lower        = var.min_lower
  min_numeric      = var.min_numeric
  min_special      = var.min_special
  min_upper        = var.min_upper
  override_special = var.override_special == "" ? null : var.override_special
  special          = var.use_special
  upper            = var.use_upper

  keepers = {
    pass_version = var.pass_version # Increment this to generate a new Password
  }
}

resource "aws_secretsmanager_secret" "secret" {
  name                    = var.name == "" ? null : var.name
  name_prefix             = var.name == "" ? var.name_prefix : null
  description             = var.description
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "secret_val" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = var.generate_random ? random_password.random_string[0].result : jsonencode("${var.secrets}")
}