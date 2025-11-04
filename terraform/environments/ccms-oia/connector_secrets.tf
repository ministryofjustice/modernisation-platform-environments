# AWS Secrets Manager - Connector Secrets

# Connector AWS Secrets

resource "aws_secretsmanager_secret" "connector_secrets" {
  name        = "${local.connector_app_name}-secrets"
  description = "Connector Application Secrets"
  #checkov:skip=CKV2_AWS_57:This policy is intentionally broad to allow the application to access its secrets.
}

resource "aws_secretsmanager_secret_version" "connector_secrets" {
  secret_id = aws_secretsmanager_secret.connector_secrets.id
  secret_string = jsonencode({
    "ccms_soa_soapHeaderUserName"               = "",
    "ccms_soa_soapHeaderUserPassword"           = "",
    "ccms_connector_service_userid"             = "",
    "ccms_connector_service_password"           = "",
    "client_opa12assess_security_user_name"     = "",
    "client_opa12assess_security_user_password" = "",
    "spring_datasource_url"                     = "",
    "spring_datasource_username"                = "",
    "spring_datasource_password"                = "",
    "opa_security_password"                     = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

# # CCMS SOA SOAP User Password
# resource "aws_secretsmanager_secret" "ccms_soa_soapHeaderUserPassword" {
#   name        = "ccms_soa_soapHeaderUserPassword"
#   description = "CCMS SOA SOAP User Password"
# }

# data "aws_secretsmanager_secret_version" "ccms_soa_soapHeaderUserPassword" {
#   secret_id = aws_secretsmanager_secret.ccms_soa_soapHeaderUserPassword.id
# }

# # Connector Service Password
# resource "aws_secretsmanager_secret" "ccms_connector_service_password" {
#   name        = "ccms_connector_service_password"
#   description = "Connector Service Password"
# }

# data "aws_secretsmanager_secret_version" "ccms_connector_service_password" {
#   secret_id = aws_secretsmanager_secret.ccms_connector_service_password.id
# }

# # Client OPA12Assess Security User Password
# resource "aws_secretsmanager_secret" "client_opa12assess_security_user_password" {
#   name        = "client_opa12assess_security_user_password"
#   description = "Client OPA12Assess Security User Password"
# }

# data "aws_secretsmanager_secret_version" "client_opa12assess_security_user_password" {
#   secret_id = aws_secretsmanager_secret.client_opa12assess_security_user_password.id
# }

# # CCMS EBS DB Password
# resource "aws_secretsmanager_secret" "spring_datasource_password" {
#   name        = "spring_datasource_password"
#   description = "CCMS EBS DB Password"
# }

# data "aws_secretsmanager_secret_version" "spring_datasource_password" {
#   secret_id = aws_secretsmanager_secret.spring_datasource_password.id
# }
