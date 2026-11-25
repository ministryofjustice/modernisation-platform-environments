# EDRMS credentials stored as key-value pairs.

resource "aws_secretsmanager_secret" "edrms" {
  name        = local.component_name
  description = "Application secrets for EDRMS"
}

resource "aws_secretsmanager_secret_version" "edrms" {
  secret_id = aws_secretsmanager_secret.edrms.id
  secret_string = jsonencode({
    spring_datasource_username = ""
    spring_datasource_password = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

data "aws_secretsmanager_secret_version" "edrms" {
  secret_id = aws_secretsmanager_secret.edrms.id
}
