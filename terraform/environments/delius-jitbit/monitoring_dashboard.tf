resource "aws_cloudwatch_dashboard" "jitbit" {
  count = local.create_blue_green ? 0 : 1

  dashboard_name = local.application_name
  dashboard_body = templatefile(
    "${path.module}/templates/dashboard.json",
    {
      account_id         = data.aws_caller_identity.current.account_id
      environment        = local.environment
      app_name           = local.application_name
      app_log_group_name = aws_cloudwatch_log_group.app_logs[0].name
      load_balancer_arn  = aws_lb.external.arn_suffix
      target_group_arn   = aws_lb_target_group.target_group_fargate[0].arn_suffix
      efs_id             = aws_efs_file_system.lucene.id
    }
  )
}

resource "aws_cloudwatch_dashboard" "jitbit_blue_green" {
  count = local.create_blue_green ? 1 : 0

  dashboard_name = local.application_name
  dashboard_body = templatefile(
    "${path.module}/templates/dashboard-blue-green.json",
    {
      account_id         = data.aws_caller_identity.current.account_id
      environment        = local.environment
      app_name           = local.application_name
      app_log_group_name_blue = aws_cloudwatch_log_group.app_logs_blue[0].name
      app_log_group_name_green = aws_cloudwatch_log_group.app_logs_green[0].name
      load_balancer_arn  = aws_lb.external.arn_suffix
      target_group_arn_blue   = aws_lb_target_group.target_group_fargate_blue[0].arn_suffix
      target_group_arn_green   = aws_lb_target_group.target_group_fargate_green[0].arn_suffix
      efs_id             = aws_efs_file_system.lucene.id
    }
  )
}
