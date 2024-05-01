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
    layers = [aws_lambda_layer_version.create_external_athena_tables_layer.arn]
    source_code_hash = data.archive_file.create_athena_external_tables.output_base64sha256
    depends_on    = [aws_cloudwatch_log_group.create_athena_external_tables_lambda]
    timeout = 200
    runtime = "python3.12"
    vpc_config {
      security_group_ids = [aws_security_group.lambda_db_security_group.id]
      subnet_ids = data.aws_subnets.shared-public.ids
    }

    environment {
      variables = {
        RDS_PRIVATE_HOST_ADDRESS = aws_db_instance.database_2022.endpoint
        RDS_DATABASE_NAMES =  join(", ", var.database_list)
        RDS_GLUE_CONNECTION_STR = aws_glue_connection.rds_sqlserver_db_glue_connection.name
        CRAWLER_OUTPUT_DB_NAME = aws_glue_catalog_database.rds_sqlserver_glue_catalog_db.name
        S3_ATHENA_OUTPUT_BUCKET_NAME = aws_s3_bucket.ap_export_bucket.id
        S3_CSV_SOURCE_BUCKET_NAME = aws_s3_bucket.dms_target_ep_s3_bucket.id
      }
    }
}