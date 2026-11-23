locals {
  dms_alert_task_arns = concat(
    [aws_dms_replication_task.full_load_replication_task.replication_task_arn],
    aws_dms_replication_task.cdc_replication_task[*].replication_task_arn
  )

  dms_alert_input_paths = {
    event   = "$.detail.eventType"
    message = "$.detail.detailMessage"
    link    = "$.detail.resourceLink"
  }
}

module "sns_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases               = ["dms/${var.db}/sns-alerts"]
  description           = "Encrypts the ${var.db} DMS alerts SNS topic"
  enable_default_policy = true
  key_statements = [
    {
      sid       = "AllowEventBridge"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["events.amazonaws.com"]
        }
      ]
    }
  ]
  deletion_window_in_days = 7

  tags = var.tags
}

resource "aws_sns_topic" "dms_events" {
  name              = "${var.db}-dms-events"
  kms_master_key_id = module.sns_kms.key_arn
  tags              = var.tags
}

data "aws_iam_policy_document" "dms_events_topic" {
  statement {
    effect    = "Allow"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.dms_events.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_cloudwatch_event_rule.dms_task_events.arn,
        aws_cloudwatch_event_rule.dms_task_events_by_category.arn,
        aws_cloudwatch_event_rule.dms_instance_events.arn,
        aws_cloudwatch_event_rule.dms_alarms.arn,
      ]
    }
  }
}

resource "aws_sns_topic_policy" "dms_events" {
  arn    = aws_sns_topic.dms_events.arn
  policy = data.aws_iam_policy_document.dms_events_topic.json
}

data "aws_secretsmanager_secret_version" "slack_webhook" {
  count     = var.slack_webhook_secret_id == null ? 0 : 1
  secret_id = var.slack_webhook_secret_id
}

resource "aws_sns_topic_subscription" "slack" {
  count     = var.slack_webhook_secret_id == null ? 0 : 1
  topic_arn = aws_sns_topic.dms_events.arn
  protocol  = "https"
  endpoint  = data.aws_secretsmanager_secret_version.slack_webhook[0].secret_string
}

# Started / stopped / reload / reading paused+resumed / deleted; DMS auto-retry "resume" starts are skipped
resource "aws_cloudwatch_event_rule" "dms_task_events" {
  name        = "${var.db}-dms-task-events"
  description = "DMS replication task state changes for ${var.db}"

  event_pattern = jsonencode({
    source        = ["aws.dms"]
    "detail-type" = ["DMS Replication Task State Change"]
    resources     = local.dms_alert_task_arns
    detail = {
      category      = ["StateChange", "Deletion"]
      detailMessage = [{ "anything-but" = { wildcard = "*resume*" } }]
    }
  })

  tags = var.tags
}

# RECOVERABLE failures are skipped: DMS retries them and sends a FATAL failure if retries run out
resource "aws_cloudwatch_event_rule" "dms_task_events_by_category" {
  name        = "${var.db}-dms-task-events-by-category"
  description = "DMS replication task creation/config/failure events for ${var.db}"

  event_pattern = jsonencode({
    source        = ["aws.dms"]
    "detail-type" = ["DMS Replication Task State Change"]
    resources     = local.dms_alert_task_arns
    detail = {
      category      = ["Creation", "ConfigurationChange", "Failure"]
      detailMessage = [{ "anything-but" = { wildcard = "*Error Level RECOVERABLE*" } }]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "dms_instance_events" {
  name        = "${var.db}-dms-instance-events"
  description = "DMS replication instance state changes for ${var.db}"

  event_pattern = jsonencode({
    source        = ["aws.dms"]
    "detail-type" = ["DMS Replication Instance State Change"]
    resources     = [aws_dms_replication_instance.instance.replication_instance_arn]
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "dms_task_events" {
  rule      = aws_cloudwatch_event_rule.dms_task_events.name
  target_id = "DMSTaskAlertToSNS"
  arn       = aws_sns_topic.dms_events.arn

  input_transformer {
    input_paths    = local.dms_alert_input_paths
    input_template = <<TEMPLATE
"ℹ️ ${var.db}: <event>"
"<message>"
TEMPLATE
  }
}

resource "aws_cloudwatch_event_target" "dms_task_events_by_category" {
  rule      = aws_cloudwatch_event_rule.dms_task_events_by_category.name
  target_id = "DMSTaskAlertToSNS"
  arn       = aws_sns_topic.dms_events.arn

  input_transformer {
    input_paths    = local.dms_alert_input_paths
    input_template = <<TEMPLATE
"🚨 ${var.db}: <event>"
"<message>"
"<link>"
TEMPLATE
  }
}

resource "aws_cloudwatch_event_target" "dms_instance_events" {
  rule      = aws_cloudwatch_event_rule.dms_instance_events.name
  target_id = "DMSInstanceAlertToSNS"
  arn       = aws_sns_topic.dms_events.arn

  input_transformer {
    input_paths    = local.dms_alert_input_paths
    input_template = <<TEMPLATE
"⚙️ ${var.db} replication instance: <event>"
"<message>"
TEMPLATE
  }
}

# CloudWatch alarms reach Slack via EventBridge (not alarm_actions) so they get readable text and reuse the topic's existing permissions
resource "aws_cloudwatch_event_rule" "dms_alarms" {
  name        = "${var.db}-dms-alarms"
  description = "CloudWatch alarms for ${var.db} entering ALARM state"

  event_pattern = jsonencode({
    source        = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    resources     = [{ prefix = "arn:aws:cloudwatch:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:alarm:${var.db}-" }]
    detail = {
      state = { value = ["ALARM"] }
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "dms_alarms" {
  rule      = aws_cloudwatch_event_rule.dms_alarms.name
  target_id = "DMSAlarmToSNS"
  arn       = aws_sns_topic.dms_events.arn

  input_transformer {
    input_paths = {
      alarm       = "$.detail.alarmName"
      description = "$.detail.configuration.description"
      reason      = "$.detail.state.reason"
    }
    input_template = <<TEMPLATE
"🚨 <alarm>"
"<description>"
"<reason>"
TEMPLATE
  }
}

# Audit trail of every DMS event; the shared log resource policy lives in the calling environment
#trivy:ignore:AVD-AWS-0017 CMK not used here
resource "aws_cloudwatch_log_group" "dms_events" {
  #checkov:skip=CKV_AWS_158:KMS not used here
  #checkov:skip=CKV_AWS_338:Retention set via variable
  name              = "/aws/events/dms/${var.db}"
  retention_in_days = var.dms_events_log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "dms_events_to_logs" {
  for_each = {
    task_events             = aws_cloudwatch_event_rule.dms_task_events.name
    task_events_by_category = aws_cloudwatch_event_rule.dms_task_events_by_category.name
    instance_events         = aws_cloudwatch_event_rule.dms_instance_events.name
  }

  rule      = each.value
  target_id = "DMSEventsToLogs"
  arn       = aws_cloudwatch_log_group.dms_events.arn
}
