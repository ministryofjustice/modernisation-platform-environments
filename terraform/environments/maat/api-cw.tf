######################################
# ECS CLOUDWATCH GROUP
######################################
resource "aws_cloudwatch_log_group" "maat_api_ecs_cw_group" {
  name              = "${local.application_name}-ECS"
  retention_in_days = 90
}