locals {
  pattern_name     = "${local.application_name}-${local.component_name}"
  lambda_role_name = local.pattern_name
  lambda_role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.lambda_role_name}"

  hosted_pickup_dlq_arns = {
    eventbridge = module.sqs_hosted_pickup_eventbridge_dlq.queue_arn
    sns         = module.sqs_hosted_pickup_sns_dlq.queue_arn
    processing  = module.sqs_hosted_pickup_dlq.queue_arn
  }
}