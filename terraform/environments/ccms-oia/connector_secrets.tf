#######################################
# AWS Secrets Manager - Connector Secrets
#######################################

# CCMS SOA SOAP User Password
resource "aws_secretsmanager_secret" "ccms_soa_soapHeaderUserPassword" {
  name        = "ccms_soa_soapHeaderUserPassword"
  description = "CCMS SOA SOAP User Password"
}

data "aws_secretsmanager_secret_version" "ccms_soa_soapHeaderUserPassword" {
  secret_id = aws_secretsmanager_secret.ccms_soa_soapHeaderUserPassword.id
}

# Connector Service Password
resource "aws_secretsmanager_secret" "ccms_connector_service_password" {
  name        = "ccms_connector_service_password"
  description = "Connector Service Password"
}

data "aws_secretsmanager_secret_version" "ccms_connector_service_password" {
  secret_id = aws_secretsmanager_secret.ccms_connector_service_password.id
}

# Client OPA12Assess Security User Password
resource "aws_secretsmanager_secret" "client_opa12assess_security_user_password" {
  name        = "client_opa12assess_security_user_password"
  description = "Client OPA12Assess Security User Password"
}

data "aws_secretsmanager_secret_version" "client_opa12assess_security_user_password" {
  secret_id = aws_secretsmanager_secret.client_opa12assess_security_user_password.id
}

# CCMS EBS DB Password
resource "aws_secretsmanager_secret" "spring_datasource_password" {
  name        = "spring_datasource_password"
  description = "CCMS EBS DB Password"
}

data "aws_secretsmanager_secret_version" "spring_datasource_password" {
  secret_id = aws_secretsmanager_secret.spring_datasource_password.id
}
