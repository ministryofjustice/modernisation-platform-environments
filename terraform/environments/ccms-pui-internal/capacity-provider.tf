# Capacity Providers

resource "aws_ecs_capacity_provider" "capacity-provider" {
  name = "${local.application_name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.cluster-scaling-group.arn
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-cp", local.application_name, local.environment)) }
  )
}
