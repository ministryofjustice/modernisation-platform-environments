
resource "aws_cloudwatch_event_rule" "redshift_scheduled_query_event_rule" {
  name        = "${var.project_id}-${var.name}-${var.env}"
  description = var.description

  schedule_expression = var.schedule_expression

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "redshift_scheduled_query_event_target" {
  rule = aws_cloudwatch_event_rule.redshift_scheduled_query_event_rule.name
  arn  = var.redshift_cluster_arn

  redshift_target {
    database = var.redshift_database_name
    secrets_manager_arn = var.redshift_secrets_manager_arn
    sql = var.sql_statement
    statement_name = aws_cloudwatch_event_rule.redshift_scheduled_query_event_rule.name
  }

  tags = var.tags
}