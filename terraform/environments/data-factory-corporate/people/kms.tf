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

# Encrypts secrets and Lambda resources, kept separate from the landing key shared with the external account.
module "corporate_general_kms_key" {
  source = "./modules/kms-key"

  alias                   = "corporate-general"
  rotation_period_in_days = 365

  providers = {
    aws = aws
  }

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "corporate-general-kms-key"
  }
}

module "corporate_quarantine_kms_key" {
  source = "./modules/kms-key"

  alias                   = "corporate-quarantine"
  rotation_period_in_days = 365

  providers = {
    aws = aws
  }

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "corporate-quarantine-kms-key"
  }
}

# Shared by the CloudTrail bucket and the CloudWatch log group it delivers to.
module "corporate_logging_kms_key" {
  source = "./modules/kms-key"

  alias                      = "corporate-logging"
  cloudtrail_name            = local.cloudtrail_name
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
    Infrastructure = "corporate-logging-kms-key"
  }
}