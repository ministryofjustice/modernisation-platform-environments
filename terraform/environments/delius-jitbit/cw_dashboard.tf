resource "aws_cloudwatch_dashboard" "jitbit" {
  dashboard_name = local.application_name
  dashboard_body = templatefile(
    "${path.module}/templates/dashboard.json",
    {
      environment       = local.environment
      app_name          = local.application_name
      load_balancer_arn = aws_lb.external.arn_suffix
      target_group_arn  = aws_lb_target_group.target_group_fargate.arn_suffix
    }
  )
}