# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "dms_alerts_topic" {
  name              = "delius-dms-alerts-topic"
  kms_master_key_id = var.account_config.kms_keys.general_shared

  http_success_feedback_role_arn = aws_iam_role.sns_logging_role.arn
  http_success_feedback_sample_rate = 100
  http_failure_feedback_role_arn = aws_iam_role.sns_logging_role.arn
}

resource "aws_iam_role" "sns_logging_role" {
  name = "sns-logging-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "sns.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
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
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.dms_alerts_topic.name]
  pagerduty_integration_key = local.pagerduty_integration_keys[local.integration_key_lookup]
}

resource "aws_iam_role" "lambda_put_metric_data_role" {
  name = "lambda-put-metric-data-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_put_metric_data_policy" {
  name = "lambda-put-metric-data-policy"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "cloudwatch:PutMetricData"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_put_metric_data_policy_attach" {
  role       = aws_iam_role.lambda_put_metric_data_role.name
  policy_arn = aws_iam_policy.lambda_put_metric_data_policy.arn
}

# Allow Cloudwatch Logging
resource "aws_iam_role_policy_attachment" "lambda_put_metric_data_logging_attach" {
  role       = aws_iam_role.lambda_put_metric_data_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# resource "local_file" "lambda_dms_replication_metric_py" {
#   filename = "${path.module}/lambda_dms_replication_metric.py"
#   content  = <<EOF
#   Cannot delete this resource as it causes an error
# EOF
# }

# data "archive_file" "lambda_dms_replication_metric_zip" {
#   type        = "zip"
#   source_file = local_file.lambda_dms_replication_metric_py.filename
#   output_path = "${path.module}/lambda_dms_replication_metric.zip"
# }

data "archive_file" "lambda_dms_replication_metric_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/dms_replication_metric.zip"
  excludes    = ["dms_replication_metric.zip"]
}

resource "aws_lambda_function" "dms_replication_metric_publisher" {
  function_name = "dms-replication-metric-publisher"
  role          = aws_iam_role.lambda_put_metric_data_role.arn
  handler       = "dms_replication_metric.lambda_handler"
  runtime       = "python3.8"
  filename      = data.archive_file.lambda_dms_replication_metric_zip.output_path
  source_code_hash = data.archive_file.lambda_dms_replication_metric_zip.output_base64sha256
  environment {
    variables = {
      METRIC_NAMESPACE = "CustomDMSMetrics",
      METRIC_NAME      = "DMSReplicationFailure"
    }
  }

  depends_on = [data.archive_file.lambda_dms_replication_metric_zip]
}

resource "aws_lambda_permission" "allow_sns_invoke_dms_replication_metric_publisher_handler" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dms_replication_metric_publisher.function_name
  principal     = "sns.amazonaws.com"

  source_arn    = aws_sns_topic.dms_events_topic.arn
}


# CloudWatch won't aggregate across dimensions for custom metrics (it will do so for some metrics published by other services, like EC2).
# resource "aws_cloudwatch_metric_alarm" "dms_replication_stopped_alarm" {
#   alarm_name          = "DMSReplicationStoppedAlarm"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "DMSReplicationStopped"
#   namespace           = "CustomDMSMetrics"
#   period              = 60
#   statistic           = "Sum"
#   threshold           = 0
#   treat_missing_data  = "ignore"
#   alarm_description   = "Alarm when Any DMS Replication Task has Stopped or Failed"
#   actions_enabled     = true
  
#   alarm_actions = [aws_sns_topic.dms_alerts_topic.arn]
# }

# Fetch all DMS replication tasks
data "aws_dms_replication_task" "all_tasks" {}

# Define a CloudWatch metric alarm with a metric math expression
resource "aws_cloudwatch_metric_alarm" "dms_replication_stopped_alarm" {
  for_each            = { for task in data.aws_dms_replication_tasks.all_tasks.replication_tasks : task.replication_task_id => task }
  alarm_name          = "DMSReplicationStoppedAlarm_${each.key}"
  alarm_description   = "Alarm when Stopped Replication Task for ${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  period              = 60
  statistic           = "Maximum"
  treat_missing_data  = "ignore"

  metric_name = "DMSReplicationStopped"
  namespace   = "CustomDMSMetrics"
  dimensions = {
    SourceId   = each.key
    EventSouce = "replication-task"
  }

  alarm_actions = [aws_sns_topic.dms_alerts_topic.arn]
}


# SNS Topic for DMS replication events
# This is NOT the same as for DMS Cloudwatch Alarms (dms_alerting)
# and is used to trigger the Lamda function if an event happens during
# DMS Replication (Events are NOT detected by CloudWatch Alarms)
resource "aws_sns_topic" "dms_events_topic" {
  name = "dms_events_topic"

  lambda_success_feedback_role_arn = aws_iam_role.sns_logging_role.arn
  lambda_success_feedback_sample_rate = 100
  lambda_failure_feedback_role_arn = aws_iam_role.sns_logging_role.arn
}

resource "aws_sns_topic_subscription" "dms_events_lambda_subscription" {
  topic_arn = aws_sns_topic.dms_events_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.dms_replication_metric_publisher.arn
}


resource "aws_dms_event_subscription" "dms_task_event_subscription" {
  name       = "dms-task-event-alerts"
  sns_topic_arn = aws_sns_topic.dms_events_topic.arn
  source_type   = "replication-task"
  event_categories = ["state change", "failure"]
  enabled = true
}