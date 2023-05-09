#### This file can be used to store secrets specific to the member account ####

data "aws_secretsmanager_secret" "tactical_products_db_secrets" {
  arn = "arn:aws:secretsmanager:eu-west-2:913862848426:secret:tactical-products-db-secrets-ox3sNi"
}

data "aws_secretsmanager_secret_version" "dms_source_credentials" {
  secret_id = data.aws_secretsmanager_secret.tactical_products_db_secrets.id
}

data "aws_iam_session_context" "member_infrastructure_access" {
  arn = "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess"
}

resource "aws_iam_role_policy" "add_secrets_manager_policy" {
  name = "execution-${var.networking[0].application}"
  role = data.aws_iam_session_context.member_infrastructure_access.issuer_name

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
           "Action": [
              "secretsmanager:*"
           ],
           "Resource": "*",
           "Effect": "Allow"
      }
    ]
  }
  EOF
}

# Cannot create a secret using the console in pre-production, so trying a different approach
resource "random_string" "username" {
  length  = 16
  lower   = true
  upper   = true
  numeric = false
  special = false
}

resource "random_password" "password" {
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = true
}

resource "aws_secretsmanager_secret" "tipstaff_db_secrets" {
  name                    = "tipstaff-db-secrets"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.tipstaff_db_secrets.id
  secret_string = jsonencode({ "TIPSTAFF_DB_USERNAME" : "${random_string.username.result}", "TIPSTAFF_DB_PASSWORD" : "${random_password.password.result}" })
}
