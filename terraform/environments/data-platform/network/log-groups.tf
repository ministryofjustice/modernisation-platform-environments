module "vpc_flow_logs_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name = "/aws/vpc/${local.application_name}-${local.environment}-flow-logs"
}

module "network_firewall_flow_logs_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name = "/aws/network-firewall/${local.application_name}-${local.environment}-flow-logs"
}

module "network_firewall_alert_logs_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name = "/aws/network-firewall/${local.application_name}-${local.environment}-alert-logs"
}

module "route53_resolver_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name = "/aws/route53-resolver/${local.application_name}-${local.environment}-logs"
}
