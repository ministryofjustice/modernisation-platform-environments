resource "aws_cloudwatch_log_group" "get_metadata_from_rds" {
  name              = "/aws/lambda/get_metadata_from_rds"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "create_athena_external_table_lambda" {
  name              = "/aws/lambda/create_athena_external_table"
  retention_in_days = 14
}