locals {
  dms_alert_task_arns = concat(
    [aws_dms_replication_task.full_load_replication_task.replication_task_arn],
    aws_dms_replication_task.cdc_replication_task[*].replication_task_arn
  )

  dms_alert_input_paths = {
    category = "$.detail.category"
    event    = "$.detail.eventType"
    message  = "$.detail.detailMessage"
    resource = "$.resources[0]"
    time     = "$.time"
  }

  dms_alert_input_template = <<TEMPLATE
{
  "SourceDB": "${var.db}",
  "Category": "<category>",
  "Event":    "<event>",
  "Resource": "<resource>",
  "Message":  "<message>",
  "Time":     "<time>"
}
TEMPLATE
}

module "sns_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.2"

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

# Started / stopped / reload / reading paused+resumed / deleted
resource "aws_cloudwatch_event_rule" "dms_task_events" {
  name        = "${var.db}-dms-task-events"
  description = "DMS replication task state changes for ${var.db}"

  event_pattern = jsonencode({
    source        = ["aws.dms"]
    "detail-type" = ["DMS Replication Task State Change"]
    resources     = local.dms_alert_task_arns
    detail = {
      category = ["StateChange", "Deletion"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "dms_task_events_by_category" {
  name        = "${var.db}-dms-task-events-by-category"
  description = "DMS replication task creation/config/failure events for ${var.db}"

  event_pattern = jsonencode({
    source        = ["aws.dms"]
    "detail-type" = ["DMS Replication Task State Change"]
    resources     = local.dms_alert_task_arns
    detail = {
      category = ["Creation", "ConfigurationChange", "Failure"]
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
    input_template = local.dms_alert_input_template
  }
}

resource "aws_cloudwatch_event_target" "dms_task_events_by_category" {
  rule      = aws_cloudwatch_event_rule.dms_task_events_by_category.name
  target_id = "DMSTaskAlertToSNS"
  arn       = aws_sns_topic.dms_events.arn

  input_transformer {
    input_paths    = local.dms_alert_input_paths
    input_template = local.dms_alert_input_template
  }
}

resource "aws_cloudwatch_event_target" "dms_instance_events" {
  rule      = aws_cloudwatch_event_rule.dms_instance_events.name
  target_id = "DMSInstanceAlertToSNS"
  arn       = aws_sns_topic.dms_events.arn

  input_transformer {
    input_paths    = local.dms_alert_input_paths
    input_template = local.dms_alert_input_template
  }
}
