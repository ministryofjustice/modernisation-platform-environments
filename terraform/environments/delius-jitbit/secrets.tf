##
# Create connection string for app
##
#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "db_app_connection_string" {
  #checkov:skip=CKV_AWS_149
  name                    = "${var.networking[0].application}-app-connection-string"
  recovery_window_in_days = 0
  tags = merge(
    local.tags,
    {
      Name = "${var.networking[0].application}-app-connection-string"
    },
  )
}

resource "aws_secretsmanager_secret_version" "db_app_connection_string" {
  secret_id     = aws_secretsmanager_secret.db_app_connection_string.id
  secret_string = "user id=;data source=${aws_db_instance.jitbit.address};initial catalog=;password="
  lifecycle {
    ignore_changes = [secret_string]
  }
}
