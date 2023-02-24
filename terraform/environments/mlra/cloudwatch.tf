locals {
  # sns variables
  pagerduty_integration_keys     = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  pagerduty_integration_key_name = local.application_data.accounts[local.environment].pagerduty_integration_key_name
  sns_topic_name                 = "${local.application_name}-${local.environment}-alerting-topic"
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
  snsTopicName          = local.sns_topic_name
}

resource "aws_sns_topic" "mlra_alerting_topic" {
  name = var.snsTopicName
}

module "pagerduty_core_alerts" {
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v1.0.0"
  # sns_topics                = [module.cwalarm.sns_topic_name] # Establish dependency with module cwalarm's sns topic
  sns_topics                = [aws_sns_topic.mlra_alerting_topic.name]
  pagerduty_integration_key = local.pagerduty_integration_keys[local.pagerduty_integration_key_name]
}
