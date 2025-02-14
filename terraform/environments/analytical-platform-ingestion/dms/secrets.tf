#### This file can be used to store secrets specific to the member account ####

resource "random_password" "password" {
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = false
}

# application_data referenced from application variables json imported

resource "aws_secretsmanager_secret" "resource_dms_secret" {
  name = "secret-string78698769876"
  # name                    = "${local.application_data.accounts[local.environment].db_identifier}_credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "resource_dms_secret_current" {
  secret_id     = aws_secretsmanager_secret.resource_dms_secret.id

  secret_string = jsonencode(
{
  "source_username": "username-string!87659!",
  "source_password": "password-string!87659!",
  "source_engine": "engine-string!87659!",
  "source_host": "host-string!87659!",
  "source_port": "port-string!87659!",
  "source_database_name": "database-string!87659!",
  "source_endpoint_id": "endpoint-id-string!87659!",
  "source_endpoint_type": "endpoint-type-string!87659!",
  "source_servername": "server-name-string!87659!"
})
}

data "aws_secretsmanager_secret" "resource_dms_secret" {
  depends_on = [aws_secretsmanager_secret_version.resource_dms_secret_current]
  arn        = aws_secretsmanager_secret_version.resource_dms_secret_current.arn
}

data "aws_secretsmanager_secret_version" "data_dms_secret_current" {
  depends_on = [aws_secretsmanager_secret_version.resource_dms_secret_current]
  secret_id  = data.aws_secretsmanager_secret.resource_dms_secret.id
}