locals {
    lambda_path = "lambdas"
}
# ------------------
# Zip Files
# ------------------

data "archive_file" "create_athena_external_tables" {
    type = "zip"
    source_file = "${local.lambda_path}/create_athena_external_tables.py"
    output_path = "${local.lambda_path}/create_athena_external_tables.zip"
}

# ------------------
# Lambda Functions
# ------------------

resource "aws_lambda_function" "create_athena_external_tables" {
    filename = "${local.lambda_path}/create_athena_external_tables.zip"
    function_name = "create_athena_external_tables"
    role = aws_iam_role.create_athena_external_tables_lambda.arn
    handler = "create_athena_external_tables.handler"
    layers = [
      "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:12",
      aws_lambda_layer_version.mojap_metadata_layer.arn,
      aws_lambda_layer_version.create_external_athena_tables_layer.arn
      ]
    source_code_hash = data.archive_file.create_athena_external_tables.output_base64sha256
    # depends_on    = [aws_cloudwatch_log_group.create_athena_external_tables_lambda]
    timeout = 200
    runtime = "python3.11"
    vpc_config {
      security_group_ids = [aws_security_group.lambda_db_security_group.id]
      subnet_ids = data.aws_subnets.shared-public.ids
    }

    environment {
      variables = {
        SECRET_NAME = aws_secretsmanager_secret.db_password.name_prefix
        DB_NAME = "test"
      }
    }
}