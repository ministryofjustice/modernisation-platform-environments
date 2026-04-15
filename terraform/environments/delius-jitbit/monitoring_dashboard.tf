resource "aws_cloudwatch_dashboard" "jitbit" {
  count = local.create_blue_green ? 0 : 1

  dashboard_name = local.application_name
  dashboard_body = templatefile(
    "${path.module}/templates/dashboard.json",
    {
      environment        = local.environment
      app_name           = local.application_name
      app_log_group_name = aws_cloudwatch_log_group.app_logs.name
      load_balancer_arn  = aws_lb.external.arn_suffix
      target_group_arn   = aws_lb_target_group.target_group_fargate[0].arn_suffix
    }
  )
}

resource "aws_cloudwatch_dashboard" "jitbit_blue" {
  count = local.create_blue_green ? 1 : 0

  dashboard_name = local.application_name
  dashboard_body = templatefile(
    "${path.module}/templates/dashboard.json",
    {
      environment        = local.environment
      app_name           = local.application_name
      app_log_group_name = aws_cloudwatch_log_group.app_logs.name
      load_balancer_arn  = aws_lb.external.arn_suffix
      target_group_arn   = aws_lb_target_group.target_group_fargate_blue[0].arn_suffix
    }
  )
}

resource "aws_cloudwatch_dashboard" "jitbit_green" {
  count = local.create_blue_green ? 1 : 0

  dashboard_name = local.application_name
  dashboard_body = templatefile(
    "${path.module}/templates/dashboard.json",
    {
      environment        = local.environment
      app_name           = local.application_name
      app_log_group_name = aws_cloudwatch_log_group.app_logs.name
      load_balancer_arn  = aws_lb.external.arn_suffix
      target_group_arn   = aws_lb_target_group.target_group_fargate_green[0].arn_suffix
    }
  )
}
