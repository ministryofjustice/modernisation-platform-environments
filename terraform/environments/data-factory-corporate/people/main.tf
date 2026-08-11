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

# data "aws_secretsmanager_secret" "external_account_id" {
#   name = "external-aws-account"
# }

# data "aws_secretsmanager_secret_version" "external_account_id" {
#   secret_id = data.aws_secretsmanager_secret.external_account_id.id
# }

locals {
  glue_catalog_arn = "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:catalog"

  #external_account_id = data.aws_secretsmanager_secret_version.external_account_id.secret_string
}

module "sherlock_landing_bucket_test" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  bucket_prefix      = "landing-sherlock-test"
  bucket_namespace   = "account-regional"
  versioning_enabled = true

  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  # Below variable and providers configuration is only relevant if 'replication_enabled' is set to true
  # replication_region  = "eu-west-2"
  providers = {
    aws.bucket-replication = aws
  }

  # Default/recommended encryption mode
  sse_algorithm  = "aws:kms"
  custom_kms_key = module.sherlock_kms_key.key_arn

  # Optional compatibility mode for uploaders that rely on bucket default
  # SSE-KMS encryption and do not send explicit SSE-KMS request headers.
  # enforce_kms_request_headers = false

  # Optional compatibility mode for services that cannot use SSE-KMS
  # sse_algorithm = "AES256"

  tags = {
    Environment = terraform.workspace
    Application = "data-factory-corporate"
    Component   = "people"
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
    bucket_name = module.sherlock_landing_bucket_test.bucket.bucket

    #currently the prefix is not optional, but should be.
    prefix      = "avature-sherlock"
    kms_key_arn = module.sherlock_kms_key.key_arn
  }

}

# module "assume_iam_role" {
#   source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/external-i-am-role?ref=external-iam-dev"
  
#   role_name = "datafactory_dev_assume_role"

#   trusted_account_id = data.aws_secretsmanager_secret_version.external_account_id.secret_string

#   bucket_arn = module.sherlock_landing_bucket_test.bucket.arn

#   s3_prefix = "avature-sherlock"

#   s3_object_actions = [
#     "s3:GetObject",
#     "s3:PutObject",
#     "s3:ListBucket"
#   ]

#   kms_key_arn = module.sherlock_kms_key.key_arn

#   kms_actions = [
#     "kms:Decrypt",
#     "kms:Encrypt",
#     "kms:GenerateDataKey",
#     "kms:DescribeKey",
#     "kms:ReEncryptFrom",
#     "kms:ReEncryptTo"
#   ]

#   glue_database_arn = module.sherlock_glue_database.glue_database_arn
#   glue_catalog_arn = local.glue_catalog_arn
#   glue_table_name = "*"

#   glue_actions =[
#     "glue:GetDatabase",
#     "glue:GetTable",
#     "glue:SearchTables",
#     "glue:DeleteTable",
#     "glue:CreateTable",
#     "glue:UpdateTable"
#   ]

#   tags = {
#     Environment = terraform.workspace
#     Application = "data-factory-corporate"
#     Component   = "people"
#     Infrastructure = "assume-iam-role"
#   }

#   }

