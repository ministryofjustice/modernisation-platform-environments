resource "aws_cloudwatch_log_group" "fin_transfer" {
  name              = "${local.fin_transfer_name}-${local.env_label}-ecs"
  retention_in_days = 30

  tags = merge(local.tags, {
    Name = "${local.fin_transfer_name}-${local.env_label}-ecs"
  })
}
