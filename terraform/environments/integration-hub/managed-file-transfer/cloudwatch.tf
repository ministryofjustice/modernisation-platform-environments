module "cloudwatch_eventbridge" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = "/aws/vendedlogs/events/event-bus/${local.application_name}-${local.component_name}"
  kms_key_id        = module.kms_cloudwatch_logs.key_arn
  retention_in_days = 30
}

module "cloudwatch_transfer" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = "/aws/transfer/${local.application_name}-${local.component_name}"
  kms_key_id        = module.kms_cloudwatch_logs.key_arn
  retention_in_days = 30
}