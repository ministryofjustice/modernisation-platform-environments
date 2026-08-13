module "sherlock_landing_bucket" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/s3-bucket?ref=313b46a604dc6aaee1d7309990388c6687272b6e"

  bucket_prefix = "landing-sherlock"
  kms_key_arn   = module.sherlock_kms_key.key_arn
  enable_malware_protection = true
  tags = {
    Environment = terraform.workspace
    Application = "data-factory-corporate"
    Component   = "people"
    Infrastructure = "sherlock-landing-bucket"
  }
}

data "aws_secretsmanager_secret" "external_account_id" {
  name = "external-aws-account"
}

data "aws_secretsmanager_secret_version" "external_account_id" {
  secret_id = data.aws_secretsmanager_secret.external_account_id.id
}

locals {
  glue_catalog_arn = "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:catalog"

  #external_account_id = data.aws_secretsmanager_secret_version.external_account_id.secret_string
}

# v3 fix: switched from the modernisation-platform-terraform-s3-bucket module to the
# moj-data-factory-modules//s3-bucket module (same one used by sherlock_landing_bucket).
# The previous module required `providers = { aws.bucket-replication = aws }`, which forced
# full evaluation of the default aws provider whose assume_role.role_arn resolves to null in
# CI, causing the "The argument \"role_arn\" is required" plan error. This module does not
# require that provider passthrough, so the plan no longer trips over the empty role_arn.
module "sherlock_landing_bucket_test" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/s3-bucket?ref=313b46a604dc6aaee1d7309990388c6687272b6e"

  bucket_prefix             = "landing-sherlock-test"
  kms_key_arn               = module.sherlock_kms_key.key_arn
  enable_malware_protection = true

  tags = {
    Environment    = terraform.workspace
    Application    = "data-factory-corporate"
    Component      = "people"
    Infrastructure = "sherlock-landing-bucket-test"
  }
}

module "sherlock_kms_key" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git//?ref=496d8bd559afebb43b78af0034ec74d8b32378ca"

  aliases = ["sherlock-landing"]
}

resource "aws_secretsmanager_secret" "external_account" {
  #checkov:skip=CKV2_AWS_57: "Secret holds a static external AWS account ID — rotation not applicable"
  name        = "external-aws-account"
  description = "AWS account permitted to assume the external role"
  kms_key_id = module.sherlock_kms_key.key_arn

  tags = {
    Environment = terraform.workspace
    Application = "data-factory-corporate"
    Component   = "people"
    Infrastructure = "sherlock-secret-id"
  }
}

module "sherlock_glue_database" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/data-factory-glue-database?ref=75a5fd1ccb6c1858508b98651030cc4c919b9d03"
  
  database_name = "sherlock_glue_database"

  storage = {
    bucket_name = module.sherlock_landing_bucket_test.bucket_name

    #currently the prefix is not optional
    prefix      = "avature-sherlock"
    kms_key_arn = module.sherlock_kms_key.key_arn
  }

}

module "assume_iam_role" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/external-i-am-role?ref=5a63095dcff8fceeac1b28e7ec4e8c8753345ed7"
  
  role_name = "datafactory_dev_assume_role"

  trusted_account_id = data.aws_secretsmanager_secret_version.external_account_id.secret_string

  bucket_arn = module.sherlock_landing_bucket_test.bucket_arn

  s3_prefix = "avature-sherlock"

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
  glue_catalog_arn = local.glue_catalog_arn
  glue_table_name = "*"

  glue_actions =[
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
