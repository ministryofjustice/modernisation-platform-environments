
# ECS Connector Application Logs
resource "aws_cloudwatch_log_group" "connector_ecs" {
  name              = "${local.connector_app_name}-ecs"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("%s-ecs-logs", local.connector_app_name)) }
  )
}
