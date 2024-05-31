resource "aws_cloudwatch_log_group" "get_metadata_from_rds_lambda" {
  name              = "/aws/lambda/get-metadata-from-rds"
  retention_in_days = 400
}

resource "aws_cloudwatch_log_group" "create_athena_external_table_lambda" {
  name              = "/aws/lambda/create_athena_external_table"
  retention_in_days = 400
}