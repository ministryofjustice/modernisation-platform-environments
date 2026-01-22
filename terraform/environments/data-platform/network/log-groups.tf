module "vpc_flow_logs_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = "/aws/vpc/${local.application_name}-${local.environment}-flow"
  kms_key_id        = module.vpc_flow_logs_kms_key.key_arn
  retention_in_days = 365
}

module "network_firewall_flow_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = "/aws/network-firewall/${local.application_name}-${local.environment}-flow"
  kms_key_id        = module.network_firewall_logs_kms_key.key_arn
  retention_in_days = 365
}

module "network_firewall_alerts_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = "/aws/network-firewall/${local.application_name}-${local.environment}-alerts"
  kms_key_id        = module.network_firewall_logs_kms_key.key_arn
  retention_in_days = 365
}

module "route53_resolver_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = "/aws/route53-resolver/${local.application_name}-${local.environment}"
  kms_key_id        = module.route53_resolver_logs_kms_key.key_arn
  retention_in_days = 365
}
