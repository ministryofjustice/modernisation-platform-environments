resource "aws_cloudwatch_log_group" "ecs" {
  name              = "${local.component_name}-${local.env_label}-ecs-logs"
  retention_in_days = 30

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-ecs-logs"
  })
}