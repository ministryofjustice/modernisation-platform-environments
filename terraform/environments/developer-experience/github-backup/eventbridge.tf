resource "aws_cloudwatch_event_rule" "github_backup_schedule" {
  count = local.is_production ? 1 : 0

  name                = local.component_name
  description         = "Daily GitHub repository backup"
  schedule_expression = local.github_backup_schedule
}

resource "aws_cloudwatch_event_target" "github_backup_schedule" {
  count = local.is_production ? 1 : 0

  rule = aws_cloudwatch_event_rule.github_backup_schedule[0].name
  arn  = module.github_backup_function[0].lambda_function_arn
}
