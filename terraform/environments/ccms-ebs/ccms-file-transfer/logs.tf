# Set up CloudWatch group and log stream and retain logs for 90 days
resource "aws_cloudwatch_log_group" "sftp_log_group" {
  name              = "${local.application_data.accounts[local.environment].app_name}-ecs"
  retention_in_days = 90

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-bc-%s-logs", local.application_name, local.environment)) }
  )
}

resource "aws_cloudwatch_log_stream" "sftp_log_stream" {
  name           = "${local.application_data.accounts[local.environment].app_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.sftp_log_group.name
}