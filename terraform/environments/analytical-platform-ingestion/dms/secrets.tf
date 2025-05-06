#### This file can be used to store secrets specific to the member account ####

module "cica_dms_tariff_database_credentials" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name       = "ingestion/dms/tariff-credentials"
  kms_key_id = module.cica_dms_credentials_kms.key_arn

  ignore_secret_changes = true
  secret_string = jsonencode({
    username = "CHANGEME"
    password = "CHANGEME"
    port     = "CHANGEME"
    host     = "CHANGEME"
  })

  create_policy       = true
  block_public_policy = true
  policy_statements = {
    read = {
      sid = "AllowDMSSourceRoleRead"
      principals = [{
        type        = "AWS"
        identifiers = [module.cica_dms_tariff_dms_implementation.dms_source_role_arn]
      }]
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["*"]
    }
  }

  tags = local.tags
}

module "cica_dms_tempus_database_credentials" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name       = "ingestion/dms/tempus-credentials"
  kms_key_id = module.cica_dms_credentials_kms.key_arn

  ignore_secret_changes = true
  secret_string = jsonencode({
    username = "CHANGEME"
    password = "CHANGEME"
    port     = "CHANGEME"
    host     = "CHANGEME"
  })

  create_policy       = true
  block_public_policy = true
  policy_statements = {
    read = {
      sid = "AllowDMSSourceRoleRead"
      principals = [{
        type        = "AWS"
        identifiers = [for database in module.cica_dms_tempus_dms_implementation : database.dms_source_role_arn]
      }]
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["*"]
    }
  }

  tags = local.tags
}
