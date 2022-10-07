module "cwalarm_1" {
  source = "./modules/cloudwatch-alarms"

  pClusterName          = " "
  pAutoscalingGroupName = " "
  pLoadBalancerName     = " "
  pTargetGroupName      = " "
  appnameenv            = "${local.application_name}-${local.environment}"
}