locals {
    lambda_path = "lambdas"
    db_name = local.is-production ? "g4s_cap_dw" : "test"
}
# ------------------
# Zip Files
# ------------------

data "archive_file" "get_metadata_from_rds" {
    type = "zip"
    source_file = "${local.lambda_path}/get_metadata_from_rds.py"
    output_path = "${local.lambda_path}/get_metadata_from_rds.zip"
}

# ------------------
# Lambda Functions
# ------------------

resource "aws_lambda_function" "get_metadata_from_rds" {
    filename = "${local.lambda_path}/get_metadata_from_rds.zip"
    function_name = "get_metadata_from_rds"
    role = aws_iam_role.create_athena_external_tables_lambda.arn
    handler = "get_metadata_from_rds.handler"
    layers = [
      "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPythonV2:69",
      "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:12",
      aws_lambda_layer_version.mojap_metadata_layer.arn,
      aws_lambda_layer_version.create_external_athena_tables_layer.arn
      ]
    source_code_hash = data.archive_file.get_metadata_from_rds.output_base64sha256
    # depends_on    = [aws_cloudwatch_log_group.create_athena_external_tables_lambda]
    timeout = 200
    runtime = "python3.11"
    vpc_config {
      security_group_ids = [aws_security_group.lambda_db_security_group.id]
      subnet_ids = data.aws_subnets.shared-public.ids
    }

    environment {
      variables = {
        SECRET_NAME = aws_secretsmanager_secret.db_glue_connection.name
        DB_NAME = local.db_name
        S3_BUCKET_NAME = aws_s3_bucket.dms_target_ep_s3_bucket.id
        LAMBDA_FUNCTION_ARN = aws_lambda_function.create_athena_external_table.arn
      }
    }
}


data "archive_file" "create_athena_external_table" {
    type = "zip"
    source_file = "${local.lambda_path}/create_athena_external_table.py"
    output_path = "${local.lambda_path}/create_athena_external_table.zip"
}

# ------------------
# Lambda Functions
# ------------------

resource "aws_lambda_function" "create_athena_external_table" {
    filename = "${local.lambda_path}/create_athena_external_table.zip"
    function_name = "create_athena_external_table"
    role = aws_iam_role.create_athena_external_tables_lambda.arn
    handler = "create_athena_external_table.handler"
    layers = [
      "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPythonV2:69",
      "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:12",
      aws_lambda_layer_version.mojap_metadata_layer.arn,
      aws_lambda_layer_version.create_external_athena_tables_layer.arn
      ]
    source_code_hash = data.archive_file.create_athena_external_table.output_base64sha256
    depends_on    = [aws_cloudwatch_log_group.create_athena_external_table_lambda]
    timeout = 200
    runtime = "python3.11"
    vpc_config {
      security_group_ids = [aws_security_group.lambda_db_security_group.id]
      subnet_ids = data.aws_subnets.shared-public.ids
    }

    environment {
      variables = {
        SECRET_NAME = aws_secretsmanager_secret.db_glue_connection.name
        DB_NAME = local.db_name
        S3_BUCKET_NAME = aws_s3_bucket.dms_target_ep_s3_bucket.id
      }
    }
}