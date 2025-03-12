# Add a local to get the keys
locals {
  feeds = [
    "FmsGeneral",
    "FmsHO",
    "FmsSpecials",
    # "MdssGeneral"
  ]
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  sns_names_map = tomap({
    "lambda_failure" : aws_sns_topic.lambda_failure.name
    "land_bucket_alarm" : aws_sns_topic.land_bucket_count.name
  })
}

resource "aws_kms_key" "metric_alarms" {
  deletion_window_in_days = 7
  description             = "Metric alarms encryption key"
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.metric-alarms-kms.json
}

data "aws_iam_policy_document" "metric-alarms-kms" {

  #checkov:skip=CKV_AWS_356: "Permissions required by sec-hub"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints - This is applied to a specific SNS topic"

  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
  }
}


#tfsec:ignore:avd-aws-0136 No encryption is enabled on the SNS topic
resource "aws_sns_topic" "lambda_failure" {
  name              = "lambda-failures"
  kms_master_key_id = aws_kms_key.metric_alarms.arn
}

# Alarm - "there is at least one error in a minute in AWS Lambda functions"
module "all_lambdas_errors_alarm" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash. No commit hash on this module
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.0"

  alarm_name          = "all-lambdas-errors"
  alarm_description   = "Lambdas with errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 0
  unit                = "Count"
  period              = 60

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  statistic   = "Maximum"

  alarm_actions = [aws_sns_topic.lambda_failure.arn]
}

#tfsec:ignore:avd-aws-0136 No encryption is enabled on the SNS topic
resource "aws_sns_topic" "land_bucket_count" {
  name              = "land-bucket-count"
  kms_master_key_id = aws_kms_key.metric_alarms.arn
}


# Alarm - "Detect when no files land in fms bucket within 24 hours"
module "files_land_bucket_alarm" {
  for_each = {
    for name in local.feeds : name => {
      name = "${name}FilesLanded"
    }
  }
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash. No commit hash on this module
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.0"

  alarm_name          = each.value.name
  alarm_description   = "Detect when not enough files land in bucket within 24 hours"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 24
  period              = 90000
  unit                = "Count"

  namespace   = "LandedFiles"
  metric_name = each.value.name
  statistic   = "Sum"

  alarm_actions = [aws_sns_topic.land_bucket_count.arn]
}


# Get the map of pagerduty integration keys from the modernisation platform account
data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}

data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

# link the sns topic to the service
module "pagerduty_core_alerts" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash. No commit hash on this module
  depends_on = [
    aws_sns_topic.lambda_failure, aws_sns_topic.land_bucket_count
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [for key, value in local.sns_names_map : value]
  pagerduty_integration_key = local.pagerduty_integration_keys["electronic_monitoring_data_alarms"]
}
