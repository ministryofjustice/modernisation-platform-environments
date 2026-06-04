locals {
  cloudwatch_log_retention_in_days              = 30
  eventbridge_default_bus_log_group_name        = "/aws/vendedlogs/events/event-bus/${local.application_name}-${local.component_name}"
  transfer_log_group_name                       = "/aws/transfer/${local.application_name}-${local.component_name}"
  vpc_flow_log_cloudwatch_log_group_name_prefix = "/aws/vpc-flow-log/${local.application_name}-${local.component_name}-"

  cloudwatch_logs_key_users = distinct([
    "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess",
    "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/${var.collaborator_access}",
  ])

  cloudwatch_logs_kms_encryption_context_arns = [
    "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.eventbridge_default_bus_log_group_name}",
    "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.transfer_log_group_name}",
    "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.application_name}-unscanned-to-processing",
    "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.application_name}-processing-to-post-scan",
    "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.vpc_flow_log_cloudwatch_log_group_name_prefix}*",
  ]
}

module "cloudwatch_eventbridge" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = local.eventbridge_default_bus_log_group_name
  kms_key_id        = module.kms_cloudwatch_logs.key_arn
  retention_in_days = local.cloudwatch_log_retention_in_days

  tags = local.tags
}

module "cloudwatch_transfer" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = local.transfer_log_group_name
  kms_key_id        = module.kms_cloudwatch_logs.key_arn
  retention_in_days = local.cloudwatch_log_retention_in_days

  tags = local.tags
}