# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "dms_alerts_topic" {
  name              = "delius-dms-alerts-topic"
  kms_master_key_id = var.account_config.kms_keys.general_shared

  http_success_feedback_role_arn    = aws_iam_role.sns_logging_role.arn
  http_success_feedback_sample_rate = 100
  http_failure_feedback_role_arn    = aws_iam_role.sns_logging_role.arn
}

resource "aws_iam_role" "sns_logging_role" {
  name = "sns-logging-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "sns.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_sns_policy" {
  role       = aws_iam_role.sns_logging_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSNSRole"
}

# Create a map of all possible replication tasks, so those that exist may have alarms applied to them.
# Note that the key of this map cannot be an apply time value, so cannot be the ARN or ID of the
# replication tasks - these should appear only as values.
locals {
  aws_dms_replication_tasks = merge(
    try(var.dms_config.user_target_endpoint.write_database, null) == null ? {} : {
      user_inbound_replication = {
        replication_task_arn = aws_dms_replication_task.user_inbound_replication[0].replication_task_arn,
        replication_task_id  = aws_dms_replication_task.user_inbound_replication[0].replication_task_id
      }
    },
    { for k in keys(local.client_account_map) :
      "business_interaction_inbound_replication_from_${k}" => {
        replication_task_arn = aws_dms_replication_task.business_interaction_inbound_replication[k].replication_task_arn
        replication_task_id  = aws_dms_replication_task.business_interaction_inbound_replication[k].replication_task_id
      }
    },
    { for k in keys(local.client_account_map) :
      "audited_interaction_inbound_replication_from_${k}" => {
        replication_task_arn = aws_dms_replication_task.audited_interaction_inbound_replication[k].replication_task_arn
        replication_task_id  = aws_dms_replication_task.audited_interaction_inbound_replication[k].replication_task_id
      }
    },
    { for k in keys(local.client_account_map) :
      "audited_interaction_checksum_inbound_replication_from_${k}" => {
        replication_task_arn = aws_dms_replication_task.audited_interaction_checksum_inbound_replication[k].replication_task_arn
        replication_task_id  = aws_dms_replication_task.audited_interaction_checksum_inbound_replication[k].replication_task_id
      }
    },
    try(var.dms_config.audit_source_endpoint.read_database, null) == null ? {} : {
      audited_interaction_outbound_replication = {
        replication_task_arn = aws_dms_replication_task.audited_interaction_outbound_replication[0].replication_task_arn
        replication_task_id  = aws_dms_replication_task.audited_interaction_outbound_replication[0].replication_task_id
      }
    },
    { for k in keys(local.client_account_map) :
      "user_outbound_replication_to_${k}" => {
        replication_task_arn = aws_dms_replication_task.user_outbound_replication[k].replication_task_arn
        replication_task_id  = aws_dms_replication_task.user_outbound_replication[k].replication_task_id
      }
    },
    try(var.dms_config.audit_source_endpoint.read_database, null) == null ? {} : {
      business_interaction_outbound_replication = {
        replication_task_arn = aws_dms_replication_task.business_interaction_outbound_replication[0].replication_task_arn
        replication_task_id  = aws_dms_replication_task.business_interaction_outbound_replication[0].replication_task_id
      }
    },
    try(var.dms_config.audit_source_endpoint.read_database, null) == null ? {} : {
      audited_interaction_checksum_outbound_replication = {
        replication_task_arn = aws_dms_replication_task.audited_interaction_checksum_outbound_replication[0].replication_task_arn
        replication_task_id  = aws_dms_replication_task.audited_interaction_checksum_outbound_replication[0].replication_task_id
      }
    }
  )
}



resource "aws_cloudwatch_metric_alarm" "dms_cdc_latency_source" {
  for_each            = local.aws_dms_replication_tasks
  alarm_name          = "dms-cdc-latency-source-${each.value.replication_task_id}"
  alarm_description   = "High CDC source latency for dms replication task for ${each.value.replication_task_id}"
  namespace           = "AWS/DMS"
  statistic           = "Average"
  metric_name         = "CDCLatencySource"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 15
  evaluation_periods  = 3
  period              = 120
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.dms_alerts_topic.arn]
  ok_actions          = [aws_sns_topic.dms_alerts_topic.arn]
  dimensions = {
    ReplicationInstanceIdentifier = aws_dms_replication_instance.dms_replication_instance.replication_instance_id
    # We only need to final element of the replication task ID (after the last :)
    ReplicationTaskIdentifier = split(":", each.value.replication_task_arn)[length(split(":", each.value.replication_task_arn)) - 1]
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "dms_cdc_latency_target" {
  for_each            = local.aws_dms_replication_tasks
  alarm_name          = "dms-cdc-latency-target-${each.value.replication_task_id}"
  alarm_description   = "High CDC target latency for dms replication task for ${each.value.replication_task_id}"
  namespace           = "AWS/DMS"
  statistic           = "Average"
  metric_name         = "CDCLatencyTarget"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 15
  evaluation_periods  = 3
  period              = 120
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.dms_alerts_topic.arn]
  ok_actions          = [aws_sns_topic.dms_alerts_topic.arn]
  dimensions = {
    ReplicationInstanceIdentifier = aws_dms_replication_instance.dms_replication_instance.replication_instance_id
    # We only need to final element of the replication task ID (after the last :)
    ReplicationTaskIdentifier = split(":", each.value.replication_task_arn)[length(split(":", each.value.replication_task_arn)) - 1]
  }
  tags = var.tags
}

# Pager duty integration

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
  integration_key_lookup     = var.dms_config.is-production ? "delius_oracle_prod_alarms" : "delius_oracle_nonprod_alarms"
}

# link the sns topic to the service
# Non-Prod alerts channel: #delius-aws-oracle-dev-alerts
# Prod alerts channel:     #delius-aws-oracle-prod-alerts
module "pagerduty_core_alerts" {
  #checkov:skip=CKV_TF_1
  depends_on = [
    aws_sns_topic.dms_alerts_topic
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v3.0.0"
  sns_topics                = [aws_sns_topic.dms_alerts_topic.name]
  pagerduty_integration_key = local.pagerduty_integration_keys[local.integration_key_lookup]
}

# We do not want to receive Pager Duty Notifications for the development->test replication out of hours.   This is because
# the development environment is shutdown each evening and at weekends.  Immediately after a shutdown occurs, the
# the CDC latency can spike, triggering the alarm.   
# It is not practical to block these alarms in PagerDuty since it does not support recurring maintenance windows.
# Therefore we want to stop the alarm being raised in the first place.   We can do this by disabling the alarm actions out
# of hours.   Cloud Watch alarms do not have this functionality natively so we use a scheduled Lambda function to implement it.
# This function will also disable the CDC task not-running alarm out of hours.
locals {
  disable_latency_alarm_defaults = {
    start_time      = null
    end_time        = null
    disable_weekend = false
  }
  # Create normalized version of map which includes above defaults if not specified for the environment
  disable_latency_alarms = merge(local.disable_latency_alarm_defaults, lookup(var.dms_config, "disable_latency_alarms", {}))
}

module "disable_out_of_hours_alarms" {
  count  = local.disable_latency_alarms.start_time == null ? 0 : 1
  source = "../../../../../modules/schedule_alarms_lambda"

  lambda_function_name = "toggle-dms-cdc-latency-alarms"

  start_time      = local.disable_latency_alarms.start_time
  end_time        = local.disable_latency_alarms.end_time
  disable_weekend = local.disable_latency_alarms.disable_weekend

  alarm_patterns = ["dms-cdc-latency-*", "dms-cdc-task-not-running-*"]

  tags = var.tags
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  #checkov:skip=CKV_AWS_60 "ignore"
  name = "dms-checker-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for Lambda (permissions to describe DMS tasks and write to the clodwatch logs)
resource "aws_iam_role_policy" "lambda_policy" {
  #checkov:skip=CKV_AWS_290 "ignore"
  #checkov:skip=CKV_AWS_50 "ignore"
  #checkov:skip=CKV_AWS_355 "ignore"
  name = "dms-checker-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dms:DescribeReplicationTasks"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData"
        ],
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}


# Creates a ZIP file which
# contains a Python script to check if any DMS replication task is not running
data "archive_file" "lambda_dms_replication_stopped_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/detect_stopped_replication.py"
  output_path = "${path.module}/lambda/detect_stopped_replication.zip"
}

# Lambda Function to check DMS replication is not running (source in Zip archive)
resource "aws_lambda_function" "dms_checker" {
  #checkov:skip=CKV_AWS_117 "ignore"
  #checkov:skip=CKV_AWS_116 "ignore"
  #checkov:skip=CKV_AWS_115 "ignore"
  #checkov:skip=CKV_AWS_173 "ignore"
  #checkov:skip=CKV_AWS_50 "ignore"
  #checkov:skip=CKV_AWS_272 "ignore"
  function_name = "dms-task-health-checker"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "detect_stopped_replication.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  filename      = "${path.module}/lambda/detect_stopped_replication.zip"

  # Automatically triggers redeploy when code changes
  source_code_hash = data.archive_file.lambda_dms_replication_stopped_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.dms_alerts_topic.arn
    }
  }
}

# EventBridge Rule to Trigger Lambda Every 15 Minutes (We hardcode this for now for simplicity - can change it if it needs to be configurable)
resource "aws_cloudwatch_event_rule" "check_dms_every_15_min" {
  name                = "check-dms-every-15-minutes"
  schedule_expression = "rate(15 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.check_dms_every_15_min.name
  target_id = "dms-task-check"
  arn       = aws_lambda_function.dms_checker.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dms_checker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.check_dms_every_15_min.arn
}

# Raising a Cloudwatch Alarm on a DMS Replication Task Event is not directly possible using the 
# Cloudwatch Alarm Integration in PagerDuty as the JSON payload is different.   Therefore, as
# workaround for this we create a custom Cloudwatch Metric which is populated by the
# DMS Health Checker Lambda Function.

resource "aws_cloudwatch_metric_alarm" "dms_alarm" {
  alarm_name          = "dms-cdc-task-not-running-in-${var.env_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DMSTaskNotRunning"
  namespace           = "Custom/DMS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 1

  alarm_description = "Triggered when any DMS replication task is not running"
  actions_enabled   = true
  alarm_actions     = [aws_sns_topic.dms_alerts_topic.arn]
  ok_actions        = [aws_sns_topic.dms_alerts_topic.arn]
}