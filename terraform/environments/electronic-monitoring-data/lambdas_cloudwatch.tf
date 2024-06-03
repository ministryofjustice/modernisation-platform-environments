resource "aws_cloudwatch_log_group" "create_athena_external_table_lambda" {
  name              = "/aws/lambda/create_athena_external_table"
  retention_in_days = 400
}