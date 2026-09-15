resource "aws_cloudwatch_dashboard" "jitbit" {
  dashboard_name = local.application_name
  dashboard_body = templatefile(
    "${path.module}/templates/dashboard-blue-green.json",
    {
      account_id               = data.aws_caller_identity.current.account_id
      environment              = local.environment
      app_name                 = local.application_name
      app_log_group_name_blue  = aws_cloudwatch_log_group.app_logs_blue.name
      app_log_group_name_green = aws_cloudwatch_log_group.app_logs_green.name
      load_balancer_arn        = aws_lb.external.arn_suffix
      target_group_arn_blue    = aws_lb_target_group.target_group_fargate_blue.arn_suffix
      target_group_arn_green   = aws_lb_target_group.target_group_fargate_green.arn_suffix
      efs_id                   = aws_efs_file_system.lucene.id
    }
  )
}
