# ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "${local.application_name_short}-${local.environment}/ecs"
  kms_key_id        = aws_kms_key.ecs-logs.arn
  retention_in_days = local.is-production ? 90 : 30

  depends_on = [aws_kms_key_policy.ecs-logs]

  tags = local.tags
}