module "sns_cloudwatch_alarms_high_priority" {
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.0"

  name              = "${local.application_name}-${local.component_name}-cloudwatch-alarms-high-priority"
  kms_master_key_id = module.kms_sns.key_arn

  topic_policy_statements = {
    cloudwatch_publish = {
      sid     = "AllowCloudWatchAlarmsPublish"
      actions = ["sns:Publish"]
      principals = [{
        type        = "Service"
        identifiers = ["cloudwatch.amazonaws.com"]
      }]
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
    chatbot_consume = {
      sid = "AllowChatbotToConsume"
      actions = [
        "sns:Subscribe",
        "sns:Receive",
        "sns:Publish",
      ]
      principals = [{
        type = "Service"
        identifiers = [
          "sns.amazonaws.com",
          "events.amazonaws.com",
          "chatbot.amazonaws.com",
        ]
      }]
    }
  }

  tags = local.tags
}

module "sns_cloudwatch_alarms_low_priority" {
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.0"

  name              = "${local.application_name}-${local.component_name}-cloudwatch-alarms-low-priority"
  kms_master_key_id = module.kms_sns.key_arn

  topic_policy_statements = {
    cloudwatch_publish = {
      sid     = "AllowCloudWatchAlarmsPublish"
      actions = ["sns:Publish"]
      principals = [{
        type        = "Service"
        identifiers = ["cloudwatch.amazonaws.com"]
      }]
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
    chatbot_consume = {
      sid = "AllowChatbotToConsume"
      actions = [
        "sns:Subscribe",
        "sns:Receive",
        "sns:Publish",
      ]
      principals = [{
        type = "Service"
        identifiers = [
          "sns.amazonaws.com",
          "events.amazonaws.com",
          "chatbot.amazonaws.com",
        ]
      }]
    }
  }

  tags = local.tags
}

module "chatbot_cloudwatch_alarms" {
  count = try(local.notification_configuration.slack_channel_id, null) != null && try(local.notification_configuration.slack_team_id, null) != null ? 1 : 0

  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  application_name = "${local.application_name}-${local.component_name}-cloudwatch-alarms"
  slack_channel_id = local.notification_configuration.slack_channel_id
  slack_team_id    = local.notification_configuration.slack_team_id
  sns_topic_arns = [
    module.sns_cloudwatch_alarms_high_priority.topic_arn,
    module.sns_cloudwatch_alarms_low_priority.topic_arn,
  ]
  tags = local.tags
}
