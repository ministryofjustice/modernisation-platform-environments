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
