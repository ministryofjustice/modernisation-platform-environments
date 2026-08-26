# Set up CloudWatch group and log stream and retain logs for 90 days
resource "aws_cloudwatch_log_group" "log_group_pui" {
  name              = "${local.application_name}-ecs"
  retention_in_days = 90

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-logs", local.application_name, local.environment)) }
  )
}

resource "aws_cloudwatch_log_stream" "log_stream_pui" {
  name           = "${local.application_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.log_group_pui.name
}