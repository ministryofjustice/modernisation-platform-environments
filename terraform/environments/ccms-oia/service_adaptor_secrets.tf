#######################################
# AWS Secrets Manager - Adaptor Secrets
#######################################

# Client OPA12Assess Security User Password
resource "aws_secretsmanager_secret" "client_opa12assess_security_user_password" {
  name        = "client_opa12assess_security_user_password"
  description = "Client OPA12Assess Security User Password"
}

data "aws_secretsmanager_secret_version" "client_opa12assess_security_user_password" {
  secret_id = aws_secretsmanager_secret.client_opa12assess_security_user_password.id
}

# Server OPA10Assess Security User Password
resource "aws_secretsmanager_secret" "server_opa10assess_security_user_password" {
  name        = "server_opa10assess_security_user_password"
  description = "Server OPA10Assess Security User Password"
}

data "aws_secretsmanager_secret_version" "server_opa10assess_security_user_password" {
  secret_id = aws_secretsmanager_secret.server_opa10assess_security_user_password.id
}
