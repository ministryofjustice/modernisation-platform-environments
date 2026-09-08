# Capacity Providers

resource "aws_ecs_capacity_provider" "capacity-provider" {
  name = "${local.application_name}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.cluster-scaling-group.arn
    managed_termination_protection = "ENABLED"

    # Drain tasks off an instance before the ASG terminates it during scale-in.
    managed_draining = "ENABLED"

    # Lets ECS automatically scale the ASG out (up to ec2_max_capacity) when
    # it needs extra instance capacity to place the new task revision
    # alongside the old one during a rolling deployment, then scale back in
    # once the deployment completes. Without this, ec2_min_capacity/
    # ec2_max_capacity are only static bounds - nothing actually triggers a
    # scale-out event, so rolling deployments stall when there is no spare
    # capacity.
    # managed_scaling {
    #   status          = "ENABLED"
    #   target_capacity = 100

    #   # Step size applies to scale-in as well as scale-out, so a value of 1
    #   # makes reclaiming post-deployment capacity take hours.
    #   minimum_scaling_step_size = 1
    #   maximum_scaling_step_size = 3
    #   instance_warmup_period    = 300
    # }
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-cp", local.application_name, local.environment)) }
  )
}
