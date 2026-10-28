module "sns_push_to_sftp" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sns/aws"
  version = "7.2.0"

  name                        = local.pattern_name
  kms_master_key_id           = module.kms_transport.key_arn
  create_topic_policy         = true
  enable_default_topic_policy = false

  topic_policy_statements = {
    AllowEventBridgePublish = {
      effect  = "Allow"
      actions = ["sns:Publish"]
      principals = [{
        type        = "Service"
        identifiers = ["events.amazonaws.com"]
      }]
      condition = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values   = [module.eventbridge_push_to_sftp.eventbridge_rule_arns["push-to-sftp"]]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  }

  subscriptions = {
    processing = {
      protocol             = "sqs"
      endpoint             = module.sqs_processing.queue_arn
      raw_message_delivery = false
      redrive_policy = jsonencode({
        deadLetterTargetArn = module.sqs_dlq["sns"].queue_arn
      })
    }
  }

  tags = local.tags
}