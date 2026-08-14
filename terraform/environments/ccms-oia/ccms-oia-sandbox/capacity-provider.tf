# Capacity Providers

resource "aws_ecs_capacity_provider" "capacity_provider_main" {
  name = "${local.first_cluster_name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.cluster_scaling_group.arn
    managed_termination_protection = "ENABLED"

    # Lets ECS automatically scale the ASG out (up to ec2_max_size) when
    # it needs extra instance capacity to place the new task revision
    # alongside the old one during a rolling deployment, then scale back in
    # once the deployment completes. Without this, ec2_min_size/
    # ec2_max_size are only static bounds - nothing actually triggers a
    # scale-out event, so rolling deployments stall when there is no spare
    # capacity.
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-cp", local.first_cluster_name, local.environment)) }
  )
}

resource "aws_ecs_capacity_provider" "capacity_provider_additional" {
  name = "${local.second_cluster_name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.cluster_scaling_group.arn
    managed_termination_protection = "ENABLED"

    # Lets ECS automatically scale the ASG out (up to ec2_max_size) when
    # it needs extra instance capacity to place the new task revision
    # alongside the old one during a rolling deployment, then scale back in
    # once the deployment completes. Without this, ec2_min_size/
    # ec2_max_size are only static bounds - nothing actually triggers a
    # scale-out event, so rolling deployments stall when there is no spare
    # capacity.
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-cp", local.second_cluster_name, local.environment)) }
  )
}