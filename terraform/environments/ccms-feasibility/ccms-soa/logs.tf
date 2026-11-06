resource "aws_cloudwatch_log_group" "admin" {
  name              = "${local.component_name}-admin-${local.env_label}-ecs"
  retention_in_days = 30

  tags = merge(local.tags, {
    Name = "${local.component_name}-admin-${local.env_label}-ecs"
  })
}

resource "aws_cloudwatch_log_group" "managed" {
  name              = "${local.component_name}-managed-${local.env_label}-ecs"
  retention_in_days = 30

  tags = merge(local.tags, {
    Name = "${local.component_name}-managed-${local.env_label}-ecs"
  })
}
