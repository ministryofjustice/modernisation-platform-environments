# AWS Secrets Manager - Adaptor Secrets

# Assess Service Adaptor AWS Secrets

resource "aws_secretsmanager_secret" "service_adaptor_secrets" {
  name        = "${local.adaptor_app_name}-secrets"
  description = "Service Adaptor Application Secrets"
  #checkov:skip=CKV2_AWS_57:This policy is intentionally broad to allow the application to access its secrets.
}

resource "aws_secretsmanager_secret_version" "service_adaptor_secrets" {
  secret_id = aws_secretsmanager_secret.service_adaptor_secrets.id
  secret_string = jsonencode({
    "client_opa12assess_security_user_name"     = "",
    "client_opa12assess_security_user_password" = "",
    "server_opa10assess_security_user_name"     = "",
    "server_opa10assess_security_user_password" = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}


# # Client OPA12Assess Security User Password
# resource "aws_secretsmanager_secret" "client_opa12assess_security_user_password" {
#   name        = "client_opa12assess_security_user_password"
#   description = "Client OPA12Assess Security User Password"
# }

# data "aws_secretsmanager_secret_version" "client_opa12assess_security_user_password" {
#   secret_id = aws_secretsmanager_secret.client_opa12assess_security_user_password.id
# }

# # Server OPA10Assess Security User Password
# resource "aws_secretsmanager_secret" "server_opa10assess_security_user_password" {
#   name        = "server_opa10assess_security_user_password"
#   description = "Server OPA10Assess Security User Password"
# }

# data "aws_secretsmanager_secret_version" "server_opa10assess_security_user_password" {
#   secret_id = aws_secretsmanager_secret.server_opa10assess_security_user_password.id
# }
