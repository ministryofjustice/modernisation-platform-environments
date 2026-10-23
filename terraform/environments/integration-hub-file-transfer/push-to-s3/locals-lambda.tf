locals {
  pattern_name     = "${local.application_name}-${local.component_name}"
  lambda_role_name = local.pattern_name

  push_to_s3_dlq_arns = {
    eventbridge = module.sqs_push_to_s3_eventbridge_dlq.queue_arn
    sns         = module.sqs_push_to_s3_sns_dlq.queue_arn
    processing  = module.sqs_push_to_s3_dlq.queue_arn
  }
}