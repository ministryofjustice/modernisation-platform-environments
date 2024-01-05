resource "aws_cloudwatch_log_group" "ecs" {
  name              = "${var.env_name}-${var.name}"
  retention_in_days = 7
  tags              = var.tags
}
