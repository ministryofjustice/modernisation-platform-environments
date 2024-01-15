######################################
# ECS CLOUDWATCH GROUP
######################################
resource "aws_cloudwatch_log_group" "maat_api_ecs_cw_group" {
  name              = "${local.application_name}-ECS"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.cloudwatch_logs_key.arn
}