
# ECS Service adaptor Application Logs
resource "aws_cloudwatch_log_group" "service_adaptor_ecs" {
  name              = "${local.adaptor_app_name}-ecs"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("%s-ecs-logs", local.adaptor_app_name)) }
  )
}