resource "aws_cloudwatch_log_group" "opahub" {
  name              = "${local.opahub_name}-${local.env_label}-ecs"
  retention_in_days = 30

  tags = merge(local.tags, {
    Name = "${local.opahub_name}-${local.env_label}-ecs"
  })
}

resource "aws_cloudwatch_log_group" "connector" {
  name              = "${local.connector_name}-${local.env_label}-ecs"
  retention_in_days = 30

  tags = merge(local.tags, {
    Name = "${local.connector_name}-${local.env_label}-ecs"
  })
}

resource "aws_cloudwatch_log_group" "adaptor" {
  name              = "${local.adaptor_name}-${local.env_label}-ecs"
  retention_in_days = 30

  tags = merge(local.tags, {
    Name = "${local.adaptor_name}-${local.env_label}-ecs"
  })
}
