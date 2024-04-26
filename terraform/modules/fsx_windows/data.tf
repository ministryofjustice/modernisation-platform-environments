data "aws_secretsmanager_secret" "this" {
  count = try(var.self_managed_active_directory, null) != null ? 1 : 0

  name = var.self_managed_active_directory.password_secret_name
}

data "aws_secretsmanager_secret_version" "this" {
  count     = length(data.aws_secretsmanager_secret.this) != 0 ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.this[0].id
}
