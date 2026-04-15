locals {

  db_instance_id = local.application_name

  rds_oracle_metrics = [
    "CPUUtilization",
    "DatabaseConnections",
    "FreeStorageSpace",
    "FreeableMemory",
    "ReadIOPS",
    "WriteIOPS",
    "ReadLatency",
    "WriteLatency"
  ]

  common_rds_config = {
    namespace           = "AWS/RDS"
    statistic           = "Average"
    period              = 300
    evaluation_periods  = 1
    threshold           = 80
    comparison_operator = "GreaterThanThreshold"
  }

  alarm_name_prefix = "${local.application_name}-alarm"
}

resource "aws_cloudwatch_metric_alarm" "rds_alarms" {
  for_each = toset(local.rds_oracle_metrics)

  alarm_name          = "${local.alarm_name_prefix}-${each.key}"
  comparison_operator = local.common_rds_config.comparison_operator
  evaluation_periods  = local.common_rds_config.evaluation_periods
  metric_name         = each.key
  namespace           = local.common_rds_config.namespace
  period              = local.common_rds_config.period
  statistic           = local.common_rds_config.statistic
  threshold           = local.common_rds_config.threshold
  alarm_description   = "Alarm for RDS Oracle metric: ${each.key}"
  alarm_actions       = [aws_sns_topic.maatdb_alerting_topic.arn]
  ok_actions          = [aws_sns_topic.maatdb_alerting_topic.arn]

  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_id
  }

  depends_on = [
    module.rds,
    aws_sns_topic.maatdb_alerting_topic
  ]

}

# Cloudwatch resources for the FTP and ZIP Lambdas

# Note that we only build these if the rest of the lambda infrastructure is flagged for creation via local.build_ftp

resource "aws_cloudwatch_metric_alarm" "ftp_lambda_error" {
  count               = local.build_ftp ? 1 : 0
  alarm_name          = "${aws_lambda_function.ftp[0].function_name}-errors"
  alarm_description   = "Alarm for ${aws_lambda_function.ftp[0].function_name} function errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "missing"

  dimensions = {
    FunctionName = aws_lambda_function.ftp[0].function_name
  }

  alarm_actions = [aws_sns_topic.maatdb_alerting_topic.arn] # optional
}

resource "aws_cloudwatch_metric_alarm" "zip_lambda_error" {
  count               = local.build_ftp ? 1 : 0
  alarm_name          = "${aws_lambda_function.zip[0].function_name}-errors"
  alarm_description   = "Alarm for ${aws_lambda_function.zip[0].function_name} function errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "missing"

  dimensions = {
    FunctionName = aws_lambda_function.zip[0].function_name
  }

  alarm_actions = [aws_sns_topic.maatdb_alerting_topic.arn]
}



####### CLOUDWATCH PAGERDUTY ALERTING

# Note - this is using the same integration for the MAAT application & so the same slack channels.

# Get the map of pagerduty integration keys from the modernisation platform account

data "aws_secretsmanager_secret" "maatdb_pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}

data "aws_secretsmanager_secret_version" "maatdb_pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.maatdb_pagerduty_integration_keys.id
}

# Add a local to get the keys. Note we are reusing the MAAT application's PagerDuty Integration & Key Name.
locals {
  maatdb_pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.maatdb_pagerduty_integration_keys.secret_string)
  maatdb_pagerduty_integration_key_name = local.application_data.accounts[local.environment].pagerduty_integration_key_name
}


# Create SNS topic
resource "aws_sns_topic" "maatdb_alerting_topic" {
  #checkov:skip=CKV_AWS_26:"Not required as only standard RDS metrics being alerted on."
  name = "${local.application_name}-${local.environment}-alerting-topic"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-alerting-topic"
    }
  )
}

# link the sns topic to the service
module "maatdb_pagerduty_core_alerts" {
  depends_on = [
    aws_sns_topic.maatdb_alerting_topic
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=0179859e6fafc567843cd55c0b05d325d5012dc4" #v2.0.0
  sns_topics                = [aws_sns_topic.maatdb_alerting_topic.name]
  pagerduty_integration_key = local.maatdb_pagerduty_integration_keys[local.maatdb_pagerduty_integration_key_name]
}


# create RDS maintenance notification 
resource "aws_db_event_subscription" "rds_maintenance_notifications" {
  count     = local.is-production ? 0 : 1
  name      = "${local.application_name}-${local.environment}-rds-maintenance"
  sns_topic = aws_sns_topic.maatdb_maintenance_topic[0].arn

  # DB instance only
  source_type = "db-instance"
  source_ids  = [module.rds.db_instance_identifier]

  # This category includes:
  # - minor version upgrade available
  # - maintenance scheduled
  # - maintenance started / completed
  event_categories = ["maintenance"]

  enabled = true

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-rds-maintenance"
  })

  depends_on = [
    module.rds,
    aws_sns_topic.maatdb_maintenance_topic[0]
  ]
}

# Create SNS topic for RDS maintenance event 
resource "aws_sns_topic" "maatdb_maintenance_topic" {
  count             = local.is-production ? 0 : 1
  name              = "${local.application_name}-${local.environment}-maintenance-topic"
  kms_master_key_id = aws_kms_key.sns_rds_events[0].arn

  depends_on = [aws_kms_key.sns_rds_events[0]]

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-maintenance-topic"
    }
  )
}

# RDS to SNS publish policy (not mandatory but safe to have)

data "aws_iam_policy_document" "rds_publish_to_sns" {
  count = local.is-production ? 0 : 1
  statement {
    sid    = "AllowRDSPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.rds.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.maatdb_maintenance_topic[0].arn]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:${module.rds.db_instance_identifier}"
      ]
    }
  }
}

resource "aws_sns_topic_policy" "rds_publish_policy" {
  count  = local.is-production ? 0 : 1
  arn    = aws_sns_topic.maatdb_maintenance_topic[0].arn
  policy = data.aws_iam_policy_document.rds_publish_to_sns[0].json
}

# KMS key policy for SNS ans RDS to use the key
resource "aws_kms_key" "sns_rds_events" {
  count               = local.is-production ? 0 : 1
  description         = "KMS key for encrypting RDS maintenance events in SNS"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # --- Allow account administrators full control ---
      {
        Sid    = "AllowAccountAdmins"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },

      # --- REQUIRED: Allow SNS to use the key ---
      {
        Sid    = "AllowSNSToUseKey"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      },

      # --- REQUIRED: Allow RDS Events to use the key ---
      {
        Sid    = "AllowRDSEventsToUseKey"
        Effect = "Allow"
        Principal = {
          Service = "events.rds.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-sns-rds-events-kms"
  })
}

# KMS alias
resource "aws_kms_alias" "sns_rds_events" {
  count         = local.is-production ? 0 : 1
  name          = "alias/${local.application_name}-${local.environment}-sns-rds-events"
  target_key_id = aws_kms_key.sns_rds_events[0].key_id
}
# Create Topic subscription 

resource "aws_sns_topic_subscription" "rds_to_slack_lambda" {
  count     = local.is-production ? 0 : 1
  topic_arn = aws_sns_topic.maatdb_maintenance_topic[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.dbmaintenance_sns_to_slack[0].arn

  depends_on = [aws_lambda_permission.allow_rds_sns_invoke[0]]
}

