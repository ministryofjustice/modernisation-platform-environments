locals {
  # sns variables
  pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  pagerduty_integration_key_name = local.application_data.accounts[local.environment].pagerduty_integration_key_name
}

data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}

data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

module "cwalarm" {
  source = "./modules/cloudwatch"

  pClusterName          = local.application_name
  pAutoscalingGroupName = "${local.application_name}-cluster-scaling-group"
  pLoadBalancerName     = module.alb.load_balancer.arn_suffix
  pTargetGroupName      = module.alb.target_group_name
  appnameenv            = "${local.application_name}-${local.environment}"
  pagerduty_integration_key = local.pagerduty_integration_keys[local.pagerduty_integration_key_name]
}
