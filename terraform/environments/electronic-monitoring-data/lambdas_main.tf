locals {
    lambda_path = "lambdas"
    db_name = local.is-production ? "g4s_cap_dw" : "test"
}
# ------------------------------------------------------
# Get Metadata from RDS Function
# ------------------------------------------------------

data "archive_file" "get_metadata_from_rds" {
    type = "zip"
    source_file = "${local.lambda_path}/get_metadata_from_rds.py"
    output_path = "${local.lambda_path}/get_metadata_from_rds.zip"
}

#checkov:skip=CKV_AWS_272
module "get_metadata_from_rds_lambda" {
  source              = "./modules/lambdas"
  filename = "${local.lambda_path}/get_metadata_from_rds.zip"
  function_name = "get-metadata-from-rds"
  role_arn = aws_iam_role.get_metadata_from_rds.arn
  role_name = aws_iam_role.get_metadata_from_rds.name
  handler = "get_metadata_from_rds.handler"
  layers = [
    "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:12",
    aws_lambda_layer_version.mojap_metadata_layer.arn,
    aws_lambda_layer_version.create_athena_table_layer.arn
    ]
  source_code_hash = data.archive_file.get_metadata_from_rds.output_base64sha256
  timeout = 900
  memory_size = 1024
  runtime = "python3.11"
  security_group_ids = [aws_security_group.lambda_db_security_group.id]
  subnet_ids = data.aws_subnets.shared-public.ids
  environment_variables = {
      SECRET_NAME = aws_secretsmanager_secret.db_glue_connection.name
      DB_NAME = local.db_name
      METADATA_STORE_BUCKET = module.metadata-s3-bucket.bucket.id
    }
  env_account_id = local.env_account_id
}



# ------------------------------------------------------
# Create Individual Athena Semantic Layer Function
# ------------------------------------------------------


data "archive_file" "create_athena_table" {
    type = "zip"
    source_file = "${local.lambda_path}/create_athena_table.py"
    output_path = "${local.lambda_path}/create_athena_table.zip"
}

module "create_athena_table" {
    source              = "./modules/lambdas"
    filename = "${local.lambda_path}/create_athena_table.zip"
    function_name = "create_athena_table"
    role_arn = aws_iam_role.create_athena_table_lambda.arn
    role_name = aws_iam_role.create_athena_table_lambda.name
    handler = "create_athena_table.handler"
    layers = [
      "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPythonV2:69",
      "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:12",
      aws_lambda_layer_version.mojap_metadata_layer.arn,
      aws_lambda_layer_version.create_athena_table_layer.arn
      ]
    source_code_hash = data.archive_file.create_athena_table.output_base64sha256
    timeout = 900
    memory_size = 1024
    runtime = "python3.11"
    security_group_ids = [aws_security_group.lambda_db_security_group.id]
    subnet_ids = data.aws_subnets.shared-public.ids
    env_account_id = local.env_account_id
    environment_variables = {
      DB_NAME = local.db_name
      S3_BUCKET_NAME = aws_s3_bucket.dms_target_ep_s3_bucket.id
      
    }
}

# ------------------------------------------------------
# Send Metadata to AP 
# ------------------------------------------------------


data "archive_file" "send_metadata_to_ap" {
    type = "zip"
    source_file = "${local.lambda_path}/send_metadata_to_ap.py"
    output_path = "${local.lambda_path}/send_metadata_to_ap.zip"
}

module "send_metadata_to_ap" {
    source              = "./modules/lambdas"
    filename = "${local.lambda_path}/send_metadata_to_ap.zip"
    function_name = "send_metadata_to_ap"
    role_arn = aws_iam_role.send_metadata_to_ap.arn
    role_name = aws_iam_role.send_metadata_to_ap.name
    handler = "send_metadata_to_ap.handler"
    source_code_hash = data.archive_file.send_metadata_to_ap.output_base64sha256
    layers = null
    timeout = 900
    memory_size = 1024
    runtime = "python3.11"
    security_group_ids = [aws_security_group.lambda_db_security_group.id]
    subnet_ids = data.aws_subnets.shared-public.ids
    env_account_id = local.env_account_id
    environment_variables = {
      REG_BUCKET_NAME = local.register_my_data_bucket
      
    }
}

resource "aws_lambda_permission" "send_metadata_to_ap" {
  statement_id  = "AllowS3ObjectMetaInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.send_metadata_to_ap.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.metadata-s3-bucket.bucket.arn
}

# ------------------------------------------------------
# Send table to AP 
# ------------------------------------------------------


data "archive_file" "send_table_to_ap" {
    type = "zip"
    source_file = "${local.lambda_path}/send_table_to_ap.py"
    output_path = "${local.lambda_path}/send_table_to_ap.zip"
}

module "send_table_to_ap" {
    source              = "./modules/lambdas"
    filename = "${local.lambda_path}/send_table_to_ap.zip"
    function_name = "send_table_to_ap"
    role_arn = aws_iam_role.send_table_to_ap.arn
    role_name = aws_iam_role.send_table_to_ap.name
    handler = "send_table_to_ap.handler"
    source_code_hash = data.archive_file.send_table_to_ap.output_base64sha256
    layers = null
    timeout = 900
    memory_size = 1024
    runtime = "python3.11"
    security_group_ids = [aws_security_group.lambda_db_security_group.id]
    subnet_ids = data.aws_subnets.shared-public.ids
    env_account_id = local.env_account_id
    environment_variables = {
      REG_BUCKET_NAME = local.register_my_data_bucket
      
    }
}

# ------------------------------------------------------
# Get Tables from DB
# ------------------------------------------------------


data "archive_file" "get_tables_from_db" {
    type = "zip"
    source_file = "${local.lambda_path}/get_tables_from_db.py"
    output_path = "${local.lambda_path}/get_tables_from_db.zip"
}

module "get_tables_from_db" {
    source              = "./modules/lambdas"
    filename = "${local.lambda_path}/get_tables_from_db.zip"
    function_name = "get_tables_from_db"
    role_arn = aws_iam_role.get_tables_from_db.arn
    role_name = aws_iam_role.get_tables_from_db.name
    handler = "get_tables_from_db.handler"
    source_code_hash = data.archive_file.get_tables_from_db.output_base64sha256
    layers = null
    timeout = 900
    memory_size = 1024
    runtime = "python3.11"
    security_group_ids = [aws_security_group.lambda_db_security_group.id]
    subnet_ids = data.aws_subnets.shared-public.ids
    env_account_id = local.env_account_id
    environment_variables = null
}
