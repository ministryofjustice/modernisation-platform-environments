#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "db_app_connection_string_sandbox" {
  count = local.is-development ? 1 : 0
  #checkov:skip=CKV_AWS_149
  name                    = "${var.networking[0].application}-app-connection-string-sandbox"
  recovery_window_in_days = 0
  tags = merge(
    local.tags,
    {
      Name = "${var.networking[0].application}-app-connection-string-sandbox"
    },
  )
}

data "aws_secretsmanager_secret_version" "rds_password" {
  count     = local.is-development ? 1 : 0
  secret_id = aws_db_instance.jitbit_sandbox[0].master_user_secret[0].secret_arn
}

resource "aws_secretsmanager_secret_version" "db_app_connection_string_sandbox" {
  count         = local.is-development ? 1 : 0
  secret_id     = aws_secretsmanager_secret.db_app_connection_string_sandbox[0].id
  secret_string = "user id=OfficeUser;data source=${aws_db_instance.jitbit_sandbox[0].address};initial catalog=Office;password=${jsondecode(data.aws_secretsmanager_secret_version.rds_password[0].secret_string)["password"]}"
  lifecycle {
    ignore_changes = [secret_string]
  }
}
