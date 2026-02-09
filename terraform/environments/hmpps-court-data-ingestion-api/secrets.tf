#### This file can be used to store secrets specific to the member account ####

module "secret_cloud_platform_account_id" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "cloud-platform-account-id"
  description = "The AWS Account ID for the Cloud Platform environment corresponding to this environment. Populate manually."
  kms_key_id  = module.secrets_kms.key_id

  ignore_secret_changes = true
  secret_string         = "populate-manually"

  tags = local.tags
}

module "secret_ingestion_api_auth_token" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name        = "ingestion-api-auth-token"
  description = "Shared secret/token used by the Lambda Authorizer to verify incoming requests. Populate manually."
  kms_key_id  = module.secrets_kms.key_id

  ignore_secret_changes = true
  secret_string         = "populate-manually"

  tags = local.tags
}

import {
  to = module.secret_cloud_platform_account_id.aws_secretsmanager_secret.this[0]
  id = "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:cloud-platform-account-id"
}

import {
  to = module.secret_ingestion_api_auth_token.aws_secretsmanager_secret.this[0]
  id = "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:ingestion-api-auth-token"
}
