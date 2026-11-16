# Capacity Providers

resource "aws_ecs_capacity_provider" "main_cluster_capacity_provider" {
  name = "${local.sftp_env_suffix}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.cluster-scaling-group.arn
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-capacity-provider", local.sftp_env_suffix)) }
  )
}
