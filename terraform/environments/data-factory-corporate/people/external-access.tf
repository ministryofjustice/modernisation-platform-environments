resource "aws_secretsmanager_secret" "external_account" {
  #checkov:skip=CKV2_AWS_57: "Secret holds a static external AWS account ID — rotation not applicable"
  name        = "sherlock-external-account-id"
  description = "AWS account permitted to assume the external role"
  kms_key_id  = module.corporate_general_kms_key.key_arn

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "sherlock-secret-id"
  }
}

resource "aws_secretsmanager_secret" "external-id" {
  #checkov:skip=CKV2_AWS_57: "External ID changes must be coordinated with Avature rather than automatically rotated"
  name        = "sherlock-external-id"
  description = "External ID Avature must supply when assuming the external role"
  kms_key_id  = module.corporate_general_kms_key.key_arn

  tags = local.tags
}

data "aws_secretsmanager_secret_version" "external-id" {
  count     = local.enable_external_iam_role ? 1 : 0
  secret_id = aws_secretsmanager_secret.external-id.id
}

data "aws_secretsmanager_secret" "external_account_id" {
  count = local.enable_external_iam_role ? 1 : 0
  name  = "sherlock-external-account-id"
}

data "aws_secretsmanager_secret_version" "external_account_id" {
  count     = local.enable_external_iam_role ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.external_account_id[0].id
}

module "assume_iam_role" {
  count  = local.enable_external_iam_role ? 1 : 0
  source = "./modules/external-iam-role"

  role_name = "datafactory_${local.environment}_assume_role"

  trusted_account_id = data.aws_secretsmanager_secret_version.external_account_id[0].secret_string
  external_id        = data.aws_secretsmanager_secret_version.external-id[0].secret_string

  bucket_arn = module.sherlock_landing_bucket_mp.bucket.arn

  s3_prefix = local.sherlock_landing_prefix

  s3_object_actions = [
    "s3:GetObject",
    "s3:PutObject",
    "s3:ListBucket"
  ]

  kms_key_arn = module.sherlock_kms_key.key_arn

  kms_actions = [
    "kms:Decrypt",
    "kms:Encrypt",
    "kms:GenerateDataKey",
    "kms:DescribeKey",
    "kms:ReEncryptFrom",
    "kms:ReEncryptTo"
  ]

  glue_database_arn = module.sherlock_glue_database.glue_database_arn
  glue_catalog_arn  = local.glue_catalog_arn
  glue_table_name   = "*"

  glue_actions = [
    "glue:GetDatabase",
    "glue:GetTable",
    "glue:SearchTables",
    "glue:DeleteTable",
    "glue:CreateTable",
    "glue:UpdateTable"
  ]

  tags = {
  }

}

# Glue IAM permissions alone do not authorise access to Lake Formation-governed tables.
# Grant our local assumed role catalogue access matching its Glue IAM scope, including
# DROP for DeleteTable; these grants do not change its S3 prefix restrictions.
resource "aws_lakeformation_permissions" "external-sherlock-database" {
  count = local.enable_external_iam_role ? 1 : 0

  principal   = module.assume_iam_role[0].role_arn
  permissions = ["DESCRIBE", "CREATE_TABLE"]

  database {
    name       = module.sherlock_glue_database.glue_database_name
    catalog_id = data.aws_caller_identity.current.account_id
  }

  depends_on = [aws_lakeformation_data_lake_settings.your_lake_settings_name]
}

resource "aws_lakeformation_permissions" "external-sherlock-tables" {
  count = local.enable_external_iam_role ? 1 : 0

  principal   = module.assume_iam_role[0].role_arn
  permissions = ["DESCRIBE", "ALTER", "DROP"]

  table {
    database_name = module.sherlock_glue_database.glue_database_name
    catalog_id    = data.aws_caller_identity.current.account_id
    wildcard      = true
  }

  depends_on = [aws_lakeformation_data_lake_settings.your_lake_settings_name]
}