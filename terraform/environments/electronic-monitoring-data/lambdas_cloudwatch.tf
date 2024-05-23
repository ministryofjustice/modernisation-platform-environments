resource "aws_cloudwatch_log_group" "create_athena_external_tables_lambda" {
  name              = "/aws/lambda/create_athena_external_tables"
  retention_in_days = 14
}