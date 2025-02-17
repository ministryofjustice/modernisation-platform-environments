#tfsec:ignore:avd-aws-0136 No encryption is enabled on the SNS topic
resource "aws_sns_topic" "lambda_failure" {
  name              = "lambda-failures"
  kms_master_key_id = "alias/aws/sns"
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
  period              = 60
  unit                = "Count"

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  statistic   = "Maximum"

  alarm_actions = [aws_sns_topic.lambda_failure.arn]
}

#tfsec:ignore:avd-aws-0136 No encryption is enabled on the SNS topic
resource "aws_sns_topic" "fms_land_bucket_count" {
  name              = "fms-land-bucket-count"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_cloudwatch_log_metric_filter" "s3_file_arrivals" {
  count = local.is-development ? 0 : 1

  name           = "fms-land-file-arrivals"
  pattern        = "{ $.eventName = PutObject }"
  log_group_name = aws_cloudwatch_log_group.s3_events[0].name

  metric_transformation {
    name          = "FileArrivals"
    namespace     = "Custom/S3"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_group" "s3_events" {
  count = local.is-development ? 0 : 1

  name              = "/aws/s3/fms-landing"
  retention_in_days = 30
}

# Bucket policy cloudtrail to dump into log bucket
data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  count = local.is-development ? 0 : 1

  statement {
    sid    = "DenyNonSecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      module.s3-logging-bucket.bucket.arn,
      "${module.s3-logging-bucket.bucket.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Deny non-TLS 1.2
  statement {
    sid    = "DenyOutdatedTLS"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      module.s3-logging-bucket.bucket.arn,
      "${module.s3-logging-bucket.bucket.arn}/*"
    ]

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [module.s3-logging-bucket.bucket.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${module.s3-logging-bucket.bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_cloudtrail" "s3_events" {
  count = local.is-development ? 0 : 1

  name                          = "fms-landing-file-monitoring"
  s3_bucket_name                = module.s3-logging-bucket.bucket.id
  include_global_service_events = false
  is_multi_region_trail         = false

  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${module.s3-fms-general-landing-bucket.bucket_arn}/"]
    }
  }
}

# Alarm - "Detect when no files land in fms bucket within 24 hours"
module "files_in_fms_land_bucket_alarm" {
  count = local.is-development ? 0 : 1
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash. No commit hash on this module
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.0"

  alarm_name          = "fms-land-not-enough-files"
  alarm_description   = "Detect when not enough files land in fms bucket within 24 hours"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 51
  period              = 90000
  unit                = "Count"

  namespace   = "Custom/S3"
  metric_name = "FileArrivals"
  statistic   = "Sum"

  dimensions = {
    BucketName  = module.s3-fms-general-landing-bucket.bucket_id
    StorageType = "StandardStorage"
  }

  alarm_actions = [aws_sns_topic.fms_land_bucket_count.arn]
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

# Add a local to get the keys
locals {
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  sns_names_map = tomap({
    "lambda_failure" : aws_sns_topic.lambda_failure.name
    "fms_bucket_alarm" : aws_sns_topic.fms_land_bucket_count.name
  })
}

# link the sns topic to the service
module "pagerduty_core_alerts" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash. No commit hash on this module
  depends_on = [
    aws_sns_topic.lambda_failure, aws_sns_topic.fms_land_bucket_count
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [for key, value in local.sns_names_map : value]
  pagerduty_integration_key = local.pagerduty_integration_keys["electronic_monitoring_data_alarms"]
}
