#split out
locals {
  aliases                = ["sherlock-landing"]
  application            = "data-factory-corporate"
  component              = "people"
  eventbridge_rule_name  = "eventbridge-malware-rule"
}

resource "aws_secretsmanager_secret" "external_account" {
  #checkov:skip=CKV2_AWS_57: "Secret holds a static external AWS account ID — rotation not applicable"
  name        = "external-aws-account"
  description = "AWS account permitted to assume the external role"
  kms_key_id  = module.sherlock_kms_key.key_arn

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "sherlock-secret-id"
  }
}


module "sherlock_kms_key" {
  source = "./modules/kms-key"

  alias                   = "sherlock-landing"
  rotation_period_in_days = 365

  providers = {
    aws = aws
  }

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "sherlock-kms-key"
  }
}

module "sherlock_quarantine_kms_key" {
  source = "./modules/kms-key"

  alias                   = "sherlock-quarantine"
  rotation_period_in_days = 365

  providers = {
    aws = aws
  }

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "sherlock-quarantine-kms-key"
  }
}

# Shared by the CloudTrail bucket and the CloudWatch log group it delivers to.
module "sherlock_logging_kms_key" {
  source = "./modules/kms-key"

  alias                      = "sherlock-logging"
  cloudtrail_name            = "sherlock-cloudtrail"
  eventbridge_sns_topic_name = "${local.eventbridge_rule_name}-alerts"
  enable_cloudwatch_logs     = true
  rotation_period_in_days    = 365

  providers = {
    aws = aws
  }

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "sherlock-logging-kms-key"
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
}

module "sherlock_landing_bucket_mp" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  bucket_prefix      = "landing-sherlock-${local.environment}-"
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
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "sherlock-landing-bucket-${local.environment}"
  }
}

module "sherlock_quarantine_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  bucket_prefix      = "sherlock-quarantine-${local.environment}"
  bucket_namespace   = "account-regional"
  versioning_enabled = false
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
  custom_kms_key = module.sherlock_quarantine_kms_key.key_arn

  # Optional compatibility mode for uploaders that rely on bucket default
  # SSE-KMS encryption and do not send explicit SSE-KMS request headers.
  # enforce_kms_request_headers = false

  # Optional compatibility mode for services that cannot use SSE-KMS
  # sse_algorithm = "AES256"

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "sherlock-quarantine-bucket-${local.environment}"
  }
}

# cloudtrail logging bucket

module "corp_people_logging_bucket" {
  source = "./modules/logging-bucket-cloudtrail"

  bucket_prefix                    = "logging-sherlock-${local.environment}-mp"
  cloudtrail_name                  = "sherlock-cloudtrail"
  kms_key_arn                      = module.sherlock_logging_kms_key.key_arn
  cloudwatch_log_retention_in_days = 365

  providers = {
    aws = aws
  }

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "sherlock-logging-bucket-${local.environment}"
  }
}

data "aws_iam_roles" "modernisation_platform_sandbox_role" {
  name_regex  = "AWSReservedSSO_modernisation-platform-sandbox_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

resource "aws_lakeformation_data_lake_settings" "your_lake_settings_name" {
  admins = concat(
    [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-plan",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-apply",
    ],
    [
      for role_name in data.aws_iam_roles.modernisation_platform_sandbox_role.names :
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/${role_name}"
    ]
  )
}

module "sherlock_glue_database" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/data-factory-glue-database?ref=75a5fd1ccb6c1858508b98651030cc4c919b9d03"

  database_name = "sherlock_glue_database_${local.environment}"

  storage = {
    bucket_name = module.sherlock_landing_bucket_mp.bucket.bucket

    #currently the prefix is not optional
    prefix      = "avature-sherlock-${local.environment}"
    kms_key_arn = module.sherlock_kms_key.key_arn
  }

}

module "assume_iam_role" {
  source = "./modules/external-iam-role"

  role_name = "datafactory_${local.environment}_assume_role"

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

# Eventbridge rule

module "data_factory_guardduty_eventbridge" {
  source = "./modules/guardduty-eventbridge"

  name = local.eventbridge_rule_name

  bucket_names = [module.sherlock_landing_bucket_mp.bucket.bucket]

  scan_result_statuses = ["THREATS_FOUND", "FAILED", "ACCESS_DENIED", "UNSUPPORTED", "NO_THREATS_FOUND"]

  target_lambda_name = module.data_factory_guardduty_lambda.name

  target_lambda_arn = module.data_factory_guardduty_lambda.arn
  kms_key_arn       = module.sherlock_logging_kms_key.key_arn

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "sherlock-eventbridge-rule"
  }
}

output "guardduty_scan_alerts_topic_arn" {
  description = "SNS topic to connect to a Slack channel in Amazon Q Developer in chat applications."
  value       = module.data_factory_guardduty_eventbridge.scan_alerts_topic_arn
}

# guardduty malware scan


module "data_factory_guardduty_scan" {

  source = "./modules/guardduty-malware-scan"


  bucket_name = module.sherlock_landing_bucket_mp.bucket.bucket
  bucket_arn  = module.sherlock_landing_bucket_mp.bucket.arn
  #object_prefixes = []

  kms_key_arn = module.sherlock_kms_key.key_arn


  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "sherlock-guardduty-malware-scan"
  }
}

# lambda function for guardduty malware scan

module "data_factory_guardduty_lambda" {

  source = "./modules/guardduty-lambda"

  name = "guardduty_lambda"

  lambda_kms_key_arn = module.sherlock_kms_key.key_arn

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "sherlock-guardduty-malware-scan"
  }

  quarantine_statuses = ["THREATS_FOUND", "FAILED", "ACCESS_DENIED", "UNSUPPORTED", "NO_THREATS_FOUND"]

  eventbridge_rule_arn = module.data_factory_guardduty_eventbridge.rule_arn

  quarantine_bucket_name = module.sherlock_quarantine_bucket.bucket.bucket
  quarantine_bucket_arn  = module.sherlock_quarantine_bucket.bucket.arn
  quarantine_kms_key_arn = module.sherlock_quarantine_kms_key.key_arn

  s3_bucket_name        = module.sherlock_landing_bucket_mp.bucket.bucket
  s3_bucket_arn         = module.sherlock_landing_bucket_mp.bucket.arn
  s3_bucket_kms_key_arn = module.sherlock_kms_key.key_arn

}
