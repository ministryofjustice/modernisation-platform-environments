#### This file can be used to store secrets specific to the member account ####

# CCMS EBS Database Password
resource "aws_secretsmanager_secret" "spring_datasource_password" {
  name        = "spring_datasource_password"
  description = "CCMS EBS Database Password for user XXCCMS_PUI"
}

data "aws_secretsmanager_secret_version" "spring_datasource_password" {
  secret_id = aws_secretsmanager_secret.spring_datasource_password.id
}

# Portal Certificate - not required but using as placeholder
resource "aws_secretsmanager_secret" "portal_certificate" {
  name        = "portal_certificate"
  description = "Portal Certificate"
}

data "aws_secretsmanager_secret_version" "portal_certificate" {
  secret_id = aws_secretsmanager_secret.portal_certificate.id
}

# SP Certificate - not sure what this is for - placeholder
resource "aws_secretsmanager_secret" "spcert" {
  name        = "spcert"
  description = "SP Certificate"
}

data "aws_secretsmanager_secret_version" "spcert" {
  secret_id = aws_secretsmanager_secret.spcert.id
}

# SP Private Key - not sure what this is for - placeholder
resource "aws_secretsmanager_secret" "spprivatekey" {
  name        = "spprivatekey"
  description = "SP Private Key"
}

data "aws_secretsmanager_secret_version" "spprivatekey" {
  secret_id = aws_secretsmanager_secret.spprivatekey.id
}

# PostCode API Key - not sure what this is for - placeholder
resource "aws_secretsmanager_secret" "postcodeApiKey" {
  name        = "postcodeApiKey"
  description = "Postcode API Key"
}

data "aws_secretsmanager_secret_version" "postcodeApiKey" {
  secret_id = aws_secretsmanager_secret.postcodeApiKey.id
}

# SOA SOAP Header User Password
resource "aws_secretsmanager_secret" "ccms_soa_soapHeaderUserPassword" {
  name        = "ccms_soa_soapHeaderUserPassword"
  description = "SOA SOAP Header User Password"
}

data "aws_secretsmanager_secret_version" "ccms_soa_soapHeaderUserPassword" {
  secret_id = aws_secretsmanager_secret.ccms_soa_soapHeaderUserPassword.id
}