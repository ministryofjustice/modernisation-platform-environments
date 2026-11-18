# cloudtrail logging bucket

module "corp_people_logging_bucket" {
  source = "./modules/logging-bucket-cloudtrail"

  bucket_prefix                    = "logging-corporate-${local.environment}-mp"
  cloudtrail_name                  = local.cloudtrail_name
  kms_key_arn                      = module.corporate_logging_kms_key.key_arn
  cloudwatch_log_retention_in_days = 365

  providers = {
    aws = aws
  }

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "corporate-logging-bucket-${local.environment}"
  }
}

# Eventbridge rule

module "data_factory_guardduty_eventbridge" {
  source = "./modules/guardduty-eventbridge"

  name = local.eventbridge_rule_name

  bucket_names = [module.sherlock_landing_bucket_mp.bucket.bucket]

  # Publish matching scan results to SNS; include clean scans for notifications.
  alert_scan_result_statuses = ["THREATS_FOUND", "FAILED", "ACCESS_DENIED", "UNSUPPORTED", "NO_THREATS_FOUND"]
  # Invoke the Lambda for matching results; it tags each object and quarantines
  # only statuses listed in the Lambda module's quarantine_statuses below.
  scan_result_statuses = ["THREATS_FOUND", "FAILED", "ACCESS_DENIED", "UNSUPPORTED", "NO_THREATS_FOUND"]

  target_lambda_name = module.data_factory_guardduty_lambda.name

  target_lambda_arn = module.data_factory_guardduty_lambda.arn
  kms_key_arn       = module.corporate_logging_kms_key.key_arn

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "corporate-eventbridge-rule"
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

  lambda_kms_key_arn = module.corporate_general_kms_key.key_arn

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "sherlock-guardduty-malware-scan"
  }

  # Of the results delivered to the Lambda, move only these statuses to quarantine.
  quarantine_statuses = ["THREATS_FOUND", "FAILED", "ACCESS_DENIED", "UNSUPPORTED"]

  eventbridge_rule_arn = module.data_factory_guardduty_eventbridge.rule_arn

  quarantine_bucket_name = module.sherlock_quarantine_bucket.bucket.bucket
  quarantine_bucket_arn  = module.sherlock_quarantine_bucket.bucket.arn
  quarantine_kms_key_arn = module.corporate_quarantine_kms_key.key_arn

  s3_bucket_name        = module.sherlock_landing_bucket_mp.bucket.bucket
  s3_bucket_arn         = module.sherlock_landing_bucket_mp.bucket.arn
  s3_bucket_kms_key_arn = module.sherlock_kms_key.key_arn
}

# EventBridge rule to capture all GuardDuty Findings (not just malware scans)
resource "aws_cloudwatch_event_rule" "guardduty_all_findings" {
  name        = "${local.application}-${local.component}-guardduty-all-findings"
  description = "Capture all GuardDuty findings including network, API, and EC2 threats"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "guardduty-all-findings"
  }
}

# Route all GuardDuty findings to the existing SNS topic (which connects to Slack)
resource "aws_cloudwatch_event_target" "guardduty_all_findings_to_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_all_findings.name
  target_id = "guardduty-all-findings-sns"
  arn       = module.data_factory_guardduty_eventbridge.scan_alerts_topic_arn
}