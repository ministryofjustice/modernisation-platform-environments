module "sqs_xsiam_notifications" {
  source = "terraform-aws-modules/sqs/aws"
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  version = "5.1.0"

  count               = local.create_resources ? 1 : 0
  create_queue_policy = true
  name                = local.component_name

  queue_policy_statements = {
    s3 = {
      sid     = "AllowS3SendMessage"
      actions = ["sqs:SendMessage"]
      principals = [
        { type = "Service", identifiers = ["s3.amazonaws.com"] }
      ]
      condition = [
        {
          test     = "ArnLike"
          variable = "aws:SourceArn"
          values   = [module.s3_bucket_workspacesweb_session_logs[0].s3_bucket_arn]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  }
}

module "sqs_lambda_consumer" {
  source = "terraform-aws-modules/sqs/aws"
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  version             = "5.1.0"
  count               = local.create_resources ? 1 : 0
  create_dlq          = true
  create_queue_policy = true
  name                = "${local.component_name}-lambda-consumer"
  queue_policy_statements = {
    sns_publish = {
      sid        = "AllowSNSTopicSendMessage"
      actions    = ["sqs:SendMessage"]
      principals = [{ type = "Service", identifiers = ["sns.amazonaws.com"] }]
      conditions = [
        { test = "ArnEquals", variable = "aws:SourceArn", values = [module.s3_workspacesweb_session_logs_sns_topic.topic_arn] },
        { test = "StringEquals", variable = "aws:SourceAccount", values = [data.aws_caller_identity.current.account_id] }
      ]
    }
  }
  redrive_policy = {
    maxReceiveCount = 5
  }
  visibility_timeout_seconds = 5400
}

moved {
  from = module.sqs_s3_notifications
  to   = module.sqs_xsiam_notifications
}
