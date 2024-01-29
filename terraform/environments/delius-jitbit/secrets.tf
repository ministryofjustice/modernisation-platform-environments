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
  secret_string = "user id=;data source=aws_db_instance.jitbit.address;initial catalog=;password="
  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "s3_user_access_key" {
  # checkov:skip=CKV_AWS_149: "KMS key not required standard encryption is fine here"
  # checkov:skip=CKV2_AWS_57:Auto rotation not currently possible
  name                    = "${local.application_name}-s3-user-access-key"
  recovery_window_in_days = 0
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-s3-user-access-key"
    }
  )
}

resource "aws_secretsmanager_secret_version" "s3_user_access_key" {
  secret_id     = aws_secretsmanager_secret.s3_user_access_key.id
  secret_string = aws_iam_access_key.s3_user.id
}

resource "aws_secretsmanager_secret" "s3_user_secret_key" {
  # checkov:skip=CKV_AWS_149: "KMS key not required standard encryption is fine here"
  # checkov:skip=CKV2_AWS_57:Auto rotation not currently possible
  name                    = "${local.application_name}-s3-user-secret-key"
  recovery_window_in_days = 0
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-s3-user-secret-key"
    }
  )
}

resource "aws_secretsmanager_secret_version" "s3_user_secret_key" {
  secret_id     = aws_secretsmanager_secret.s3_user_secret_key.id
  secret_string = aws_iam_access_key.s3_user.secret
  lifecycle {
    ignore_changes = [secret_string]
  }
}