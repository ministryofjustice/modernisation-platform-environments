module "s3_workspacesweb_session_logs_sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "6.2.0"

  name = "s3-firewall-log-notifications"
  subscriptions = {
    cortex = {
      protocol = "sqs"
      endpoint = module.sqs_xsiam_notifications[0].queue_arn
    }
    lambda_consumer = {
      protocol = "sqs"
      endpoint = module.sqs_lambda_consumer[0].queue_arn
    }
  }
  topic_policy_statements = {
    allow_s3_publish = {
      actions    = ["sns:Publish"]
      principals = [{ type = "Service", identifiers = ["s3.amazonaws.com"] }]
      conditions = [
        { test = "ArnLike", variable = "aws:SourceArn", values = [module.s3_bucket_workspacesweb_session_logs[0].s3_bucket_arn] },
        { test = "StringEquals", variable = "aws:SourceAccount", values = [data.aws_caller_identity.current.account_id] }
      ]
    }
    allow_sqs_subscribe = {
      actions    = ["sns:Subscribe"]
      principals = [{ type = "AWS", identifiers = [data.aws_caller_identity.current.account_id] }]
      conditions = [
        { test = "StringEquals", variable = "sns:Protocol", values = ["sqs"] },
        { test = "StringEquals", variable = "sns:Endpoint", values = [
          module.sqs_xsiam_notifications[0].queue_arn,
          module.sqs_lambda_consumer[0].queue_arn,
        ] }
      ]
    }
  }
}
