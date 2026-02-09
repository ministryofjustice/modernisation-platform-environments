#### This file can be used to store secrets specific to the member account ####

resource "aws_secretsmanager_secret" "cloud_platform_account_id" {
  name        = "cloud-platform-account-id"
  description = "The AWS Account ID for the Cloud Platform environment corresponding to this environment. Populate manually."
  tags        = local.tags
}

resource "aws_secretsmanager_secret" "ingestion_api_auth_token" {
  name        = "ingestion-api-auth-token"
  description = "Shared secret/token used by the Lambda Authorizer to verify incoming requests. Populate manually."
  tags        = local.tags
}
