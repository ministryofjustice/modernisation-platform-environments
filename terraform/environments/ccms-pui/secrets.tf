#### This file can be used to store secrets specific to the member account ####

# PUI Application Secrets
resource "aws_secretsmanager_secret" "pui_secrets" {
  name        = "${local.application_name}-secrets"
  description = "PUI Application Secrets"
  #checkov:skip=CKV2_AWS_57:This policy is intentionally broad to allow the application to access its secrets.
}

resource "aws_secretsmanager_secret_version" "pui_secrets" {
  secret_id = aws_secretsmanager_secret.pui_secrets.id
  secret_string = jsonencode({
    spring_datasource_username       = "",
    spring_datasource_password       = "",
    spring_datasource_url            = "",
    idp_cert                         = "",
    spcert                           = "",
    spprivatekey                     = "",
    idpMetadataUrl                   = "",
    loginUrl                         = "",
    postcodeApiUrl                   = "",
    postcodeApiKey                   = "",
    user_management_api_access_token = "",
    user_management_api_hostname     = "",
    idpIdentityID                    = "",
    SpEntityId                       = "",
    SpEntityUrl                      = "",
    ccms_soa_soapHeaderUserPassword  = "",
    ccms_soa_soapHeaderUserName      = "",
    opa_security_password            = "",
    guardduty_slack_channel_id       = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

data "aws_secretsmanager_secret_version" "pui_secrets" {
  secret_id = aws_secretsmanager_secret.pui_secrets.id
}

# # CCMS EBS Database Password
# resource "aws_secretsmanager_secret" "spring_datasource_password" {
#   name        = "spring_datasource_password"
#   description = "CCMS EBS Database Password for user XXCCMS_PUI"
# }

# data "aws_secretsmanager_secret_version" "spring_datasource_password" {
#   secret_id = aws_secretsmanager_secret.spring_datasource_password.id
# }

# # Portal Certificate - not required but using as placeholder
# resource "aws_secretsmanager_secret" "portal_certificate" {
#   name        = "portal_certificate"
#   description = "Portal Certificate"
# }

# data "aws_secretsmanager_secret_version" "portal_certificate" {
#   secret_id = aws_secretsmanager_secret.portal_certificate.id
# }

# # SP Certificate - not sure what this is for - placeholder
# resource "aws_secretsmanager_secret" "spcert" {
#   name        = "spcert"
#   description = "SP Certificate"
# }

# data "aws_secretsmanager_secret_version" "spcert" {
#   secret_id = aws_secretsmanager_secret.spcert.id
# }

# # SP Private Key - not sure what this is for - placeholder
# resource "aws_secretsmanager_secret" "spprivatekey" {
#   name        = "spprivatekey"
#   description = "SP Private Key"
# }

# data "aws_secretsmanager_secret_version" "spprivatekey" {
#   secret_id = aws_secretsmanager_secret.spprivatekey.id
# }

# # PostCode API Key - not sure what this is for - placeholder
# resource "aws_secretsmanager_secret" "postcodeApiKey" {
#   name        = "postcodeApiKey"
#   description = "Postcode API Key"
# }

# data "aws_secretsmanager_secret_version" "postcodeApiKey" {
#   secret_id = aws_secretsmanager_secret.postcodeApiKey.id
# }

# # SOA SOAP Header User Password
# resource "aws_secretsmanager_secret" "ccms_soa_soapHeaderUserPassword" {
#   name        = "ccms_soa_soapHeaderUserPassword"
#   description = "SOA SOAP Header User Password"
# }

# data "aws_secretsmanager_secret_version" "ccms_soa_soapHeaderUserPassword" {
#   secret_id = aws_secretsmanager_secret.ccms_soa_soapHeaderUserPassword.id
# }

# # User Management API Access Token
# resource "aws_secretsmanager_secret" "user_management_api_access_token" {
#   name        = "user_management_api_access_token"
#   description = "User Management API Access Token"
# }

# data "aws_secretsmanager_secret_version" "user_management_api_access_token" {
#   secret_id = aws_secretsmanager_secret.user_management_api_access_token.id
# }
