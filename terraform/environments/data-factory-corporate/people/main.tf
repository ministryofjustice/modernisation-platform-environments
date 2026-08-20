resource "aws_secretsmanager_secret" "external_account" {
  #checkov:skip=CKV2_AWS_57: "Secret holds a static external AWS account ID — rotation not applicable"
  name        = "external-aws-account"
  description = "AWS account permitted to assume the external role"
  kms_key_id  = module.sherlock_kms_key.key_arn

  tags = {
    Environment    = terraform.workspace
    Application    = "data-factory-corporate"
    Component      = "people"
    Infrastructure = "sherlock-secret-id"
  }
}


module "sherlock_kms_key" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git//?ref=496d8bd559afebb43b78af0034ec74d8b32378ca"

  aliases = ["sherlock-landing"]
}

# module "sherlock_quarantine_bucket" {
#   source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/s3-bucket?ref=313b46a604dc6aaee1d7309990388c6687272b6e"

#   bucket_prefix             = "quarantine-sherlock"
#   kms_key_arn               = module.sherlock_kms_key.key_arn
#   enable_malware_protection = true
#   tags = {
#     Environment    = terraform.workspace
#     Application    = "data-factory-corporate"
#     Component      = "people"
#     Infrastructure = "sherlock-quarantine-bucket"
#   }
# }

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

module "sherlock_landing_bucket_mp" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  bucket_prefix      = "landing-sherlock-test-mp"
  bucket_namespace   = "account-regional"
  versioning_enabled = true
  force_destroy      = true

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
    Environment    = terraform.workspace
    Application    = "data-factory-corporate"
    Component      = "people"
    Infrastructure = "sherlock-landing-bucket-test"
  }
}

module "sherlock_quarantine_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  bucket_prefix      = "landing-sherlock-quarantine-test-mp"
  bucket_namespace   = "account-regional"
  versioning_enabled = true
  force_destroy      = true

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
    Environment    = terraform.workspace
    Application    = "data-factory-corporate"
    Component      = "people"
    Infrastructure = "sherlock-quarantine-bucket-test"
  }
}

data "aws_iam_roles" "modernisation_platform_sandbox_role" {
  name_regex  = "AWSReservedSSO_modernisation-platform-sandbox_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

resource "aws_lakeformation_data_lake_settings" "your_lake_settings_name" {
  admins = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-plan",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-apply",
  ]
}


module "sherlock_glue_database" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/data-factory-glue-database?ref=75a5fd1ccb6c1858508b98651030cc4c919b9d03"

  database_name = "sherlock_glue_database"

  storage = {
    bucket_name = module.sherlock_landing_bucket_mp.bucket.bucket

    #currently the prefix is not optional
    prefix      = "avature-sherlock"
    kms_key_arn = module.sherlock_kms_key.key_arn
  }

}

module "assume_iam_role" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/external-i-am-role?ref=5a63095dcff8fceeac1b28e7ec4e8c8753345ed7"

  role_name = "datafactory_dev_assume_role"

  trusted_account_id = data.aws_secretsmanager_secret_version.external_account_id.secret_string

  bucket_arn = module.sherlock_landing_bucket_mp.bucket.arn

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


resource "aws_iam_role" "assume_external_role" {
  name = "datafactory_assume_external_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy_document" "allow_assume_external_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    resources = [
      "arn:aws:iam::${data.aws_secretsmanager_secret_version.external_account_id.secret_string}:role/datafactory_dev_assume_role"
    ]
  }
}

resource "aws_iam_role_policy" "allow_assume_external_role" {
  name   = "allow-assume-external-role"
  role   = aws_iam_role.assume_external_role.name
  policy = data.aws_iam_policy_document.allow_assume_external_role.json
}

# Eventbridge rule

module "data_factory_guardduty_eventbridge" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/guardduty-eventbridge?ref=9dc8fb57d5f96f92b6155c7c2a4deb1b2d4d22a7"

  name = "eventbridge_malware_rule"

  bucket_names = [module.sherlock_landing_bucket_mp.bucket.bucket]

  scan_result_statuses = ["THREATS_FOUND","FAILED", "ACCESS_DENIED"]

  target_lambda_name = module.data_factory_guardduty_lambda.name

    target_lambda_arn = module.data_factory_guardduty_lambda.arn

  tags = {
    Environment    = terraform.workspace
    Application    = "data-factory-corporate"
    Component      = "people"
    Infrastructure = "sherlock-eventbridge-rule"
  }
}

# guardduty malware scan


module "data_factory_guardduty_scan" {

  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/guardduty-malware-scan?ref=9dc8fb57d5f96f92b6155c7c2a4deb1b2d4d22a7"


    bucket_name = module.sherlock_landing_bucket_mp.bucket.bucket
    bucket_arn = module.sherlock_landing_bucket_mp.bucket.arn
    object_prefixes = []

    kms_key_arn = module.sherlock_kms_key.key_arn


  tags = {
    Environment    = terraform.workspace
    Application    = "data-factory-corporate"
    Component      = "people"
    Infrastructure = "sherlock-guardduty-malware-scan"
  }
  }

# lambda function for guardduty malware scan

module "data_factory_guardduty_lambda" {

  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/guardduty-lambda?ref=5a7c9ee3b60871f82ac63a19fc38e3131ac75dcc"

    name = "guardduty_lambda"

    tags = {
        Project     = "Avature"
        Owner       = "CorporateDataEngineering"
        Environment = terraform.workspace
        }

    eventbridge_rule_arn = module.data_factory_guardduty_eventbridge.rule_arn

    quarantine_bucket_name = module.sherlock_quarantine_bucket.bucket.bucket
    quarantine_bucket_arn = module.sherlock_quarantine_bucket.bucket.arn
    quarantine_kms_key_arn = module.sherlock_kms_key.key_arn

    s3_bucket_name = module.sherlock_landing_bucket_mp.bucket.bucket
    s3_bucket_arn = module.sherlock_landing_bucket_mp.bucket.arn
    s3_bucket_kms_key_arn = module.sherlock_kms_key.key_arn

}