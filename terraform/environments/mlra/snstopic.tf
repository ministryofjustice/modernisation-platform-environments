#Get Pagerduty keys from modplatform
locals {
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  sns_topic_name = "${local.application_name}-${local.environment}-alerting-topic"
}

data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}

data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}


#TODO currently the cloud watch module is ready but is missing a few key imputs from the ALB setup
#just waiting for these to be complete before making this section live

# module "cwalarm" {
#  source = "./module/cloudwatch"
#
#  pClusterName = " "
#  pAutoscalingGroupName = " "
#  pLoadBalancerName = " "
#  pTargetGroupName = aws_lb_target_group.alb_target_group.name
#  appnameenv = "${local.application_name}-${local.environment}"
#  snsTopicName = local.sns_topic_name
# }
#
# module "pagerduty_core_alerts" {
#   depends_on = [
#     module.cwalarm
#   ]
#   source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v1.0.0"
#   sns_topics                = [local.sns_topic_name]
#   pagerduty_integration_key = local.pagerduty_integration_keys["core_alerts_cloudwatch"]
# }
