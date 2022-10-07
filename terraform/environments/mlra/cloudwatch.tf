odule "cwalarm_1" {
  source = "./modules/cloudwatch"

  pClusterName = " "
  pAutoscalingGroupName = " "
  pLoadBalancerName = " "
  pTargetGroupName = aws_lb_target_group.alb_target_group.name 
  appnameenv = "${local.application_name}-${local.environment}"
}