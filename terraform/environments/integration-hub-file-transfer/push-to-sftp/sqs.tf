module "sqs_push_to_sftp_dlq" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  for_each = toset(["eventbridge", "sns", "processing"])

  name                       = each.key == "processing" ? "${local.pattern_name}-dlq" : "${local.pattern_name}-${each.key}-dlq"
  use_name_prefix            = false
  create_dlq                 = false
  create_queue_policy        = each.key != "processing"
  kms_master_key_id          = module.kms_push_to_sftp.key_arn
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 360
  receive_wait_time_seconds  = 20

  queue_policy_statements = each.key == "processing" ? {} : {
    AllowServiceDelivery = {
      effect  = "Allow"
      actions = ["sqs:SendMessage"]
      principals = [{
        type        = "Service"
        identifiers = [each.key == "sns" ? "sns.amazonaws.com" : "events.amazonaws.com"]
      }]
      condition = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values   = [each.key == "sns" ? module.sns_push_to_sftp.topic_arn : module.eventbridge_push_to_sftp.eventbridge_rule_arns["push-to-sftp"]]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  }

  redrive_allow_policy = {
    for key, value in {
      redrivePermission = "byQueue"
      sourceQueueArns   = [module.sqs_push_to_sftp.queue_arn]
    } : key => value if each.key == "processing"
  }

  tags = local.tags
}

module "sqs_push_to_sftp" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

  name                       = local.pattern_name
  use_name_prefix            = false
  create_dlq                 = false
  create_queue_policy        = true
  kms_master_key_id          = module.kms_push_to_sftp.key_arn
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 5400
  receive_wait_time_seconds  = 20
  redrive_policy = {
    deadLetterTargetArn = module.sqs_push_to_sftp_dlq["processing"].queue_arn
    maxReceiveCount     = 5
  }

  queue_policy_statements = {
    AllowServiceDelivery = {
      effect  = "Allow"
      actions = ["sqs:SendMessage"]
      principals = [{
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }]
      condition = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values   = [module.sns_push_to_sftp.topic_arn]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  }

  tags = local.tags
}