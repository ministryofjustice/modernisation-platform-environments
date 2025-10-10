#######################################
# AWS Secrets Manager - OPAHub Secrets
#######################################

# OPAHub App Password
resource "aws_secretsmanager_secret" "opahub_password" {
  name        = "${local.opa_app_name}-password"
  description = "OPAHub Application Password"
}

data "aws_secretsmanager_secret_version" "opahub_password" {
  secret_id = aws_secretsmanager_secret.opahub_password.id
}

# OPAHub DB Password
resource "aws_secretsmanager_secret" "opahub_db_password" {
  name        = "${local.opa_app_name}-db-password"
  description = "OPAHub MySQL RDS DB Password"
}

data "aws_secretsmanager_secret_version" "opahub_db_password" {
  secret_id = aws_secretsmanager_secret.opahub_db_password.id
}

# Weblogic Password
resource "aws_secretsmanager_secret" "wl_password" {
  name        = "${local.opa_app_name}-weblogic-password"
  description = "OPAHub Weblogic Password"
}

data "aws_secretsmanager_secret_version" "wl_password" {
  secret_id = aws_secretsmanager_secret.wl_password.id
}

# Secret Key
resource "aws_secretsmanager_secret" "secret_key" {
  name        = "${local.opa_app_name}-secret-key"
  description = "OPAHub Secret Key"
}

data "aws_secretsmanager_secret_version" "secret_key" {
  secret_id = aws_secretsmanager_secret.secret_key.id
}
