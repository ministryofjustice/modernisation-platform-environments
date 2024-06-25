locals {
  lambda_path = "lambdas"
  env_name    = local.is-production ? "prod" : "dev"
  db_name     = local.is-production ? "g4s_cap_dw" : "test"

  output_fs_json_lambda = "output_file_structure_as_json_from_zip"
}

# ------------------------------------------------------
# Get Metadata from RDS Function
# ------------------------------------------------------

data "archive_file" "get_metadata_from_rds" {
  type        = "zip"
  source_file = "${local.lambda_path}/get_metadata_from_rds.py"
  output_path = "${local.lambda_path}/get_metadata_from_rds.zip"
}

#checkov:skip=CKV_AWS_272
module "get_metadata_from_rds_lambda" {
  source        = "./modules/lambdas"
  filename      = "${local.lambda_path}/get_metadata_from_rds.zip"
  function_name = "get-metadata-from-rds"
  role_arn      = aws_iam_role.get_metadata_from_rds.arn
  role_name     = aws_iam_role.get_metadata_from_rds.name
  handler       = "get_metadata_from_rds.handler"
  layers = [
    "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:12",
    aws_lambda_layer_version.mojap_metadata_layer.arn,
    aws_lambda_layer_version.create_athena_table_layer.arn
  ]
  source_code_hash   = data.archive_file.get_metadata_from_rds.output_base64sha256
  timeout            = 900
  memory_size        = 1024
  runtime            = "python3.11"
  security_group_ids = [aws_security_group.lambda_db_security_group.id]
  subnet_ids         = data.aws_subnets.shared-public.ids
  environment_variables = {
    SECRET_NAME           = aws_secretsmanager_secret.db_glue_connection.name
    METADATA_STORE_BUCKET = module.metadata-s3-bucket.bucket.id
  }
  env_account_id = local.env_account_id
}



# ------------------------------------------------------
# Create Individual Athena Semantic Layer Function
# ------------------------------------------------------


data "archive_file" "create_athena_table" {
  type        = "zip"
  source_file = "${local.lambda_path}/create_athena_table.py"
  output_path = "${local.lambda_path}/create_athena_table.zip"
}

module "create_athena_table" {
  source   = "./modules/lambdas"
  filename = "${local.lambda_path}/create_athena_table.zip"

  function_name = "create_athena_table"
  role_arn      = aws_iam_role.create_athena_table_lambda.arn
  role_name     = aws_iam_role.create_athena_table_lambda.name
  handler       = "create_athena_table.handler"
  layers = [
    "arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPythonV2:69",
    "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python311:12",
    aws_lambda_layer_version.mojap_metadata_layer.arn,
    aws_lambda_layer_version.create_athena_table_layer.arn
  ]
  source_code_hash   = data.archive_file.create_athena_table.output_base64sha256
  timeout            = 900
  memory_size        = 1024
  runtime            = "python3.11"
  security_group_ids = [aws_security_group.lambda_db_security_group.id]
  subnet_ids         = data.aws_subnets.shared-public.ids
  env_account_id     = local.env_account_id
  environment_variables = {
    S3_BUCKET_NAME = aws_s3_bucket.dms_target_ep_s3_bucket.id
  }
}


# ------------------------------------------------------
# Send Metadata to AP
# ------------------------------------------------------


data "archive_file" "send_metadata_to_ap" {
  type        = "zip"
  source_file = "${local.lambda_path}/send_metadata_to_ap.py"
  output_path = "${local.lambda_path}/send_metadata_to_ap.zip"
}

module "send_metadata_to_ap" {
  source             = "./modules/lambdas"
  filename           = "${local.lambda_path}/send_metadata_to_ap.zip"
  function_name      = "send_metadata_to_ap"
  role_arn           = aws_iam_role.send_metadata_to_ap.arn
  role_name          = aws_iam_role.send_metadata_to_ap.name
  handler            = "send_metadata_to_ap.handler"
  source_code_hash   = data.archive_file.send_metadata_to_ap.output_base64sha256
  layers             = null
  timeout            = 900
  memory_size        = 1024
  runtime            = "python3.11"
  security_group_ids = null
  subnet_ids         = data.aws_subnets.shared-public.ids
  env_account_id     = local.env_account_id
  environment_variables = {
    METADATA_BUCKET_NAME = local.is-production ? "mojap-metadata-prod" : "mojap-metadata-dev"

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
# get file keys for table
# ------------------------------------------------------


data "archive_file" "get_file_keys_for_table" {
  type        = "zip"
  source_file = "${local.lambda_path}/get_file_keys_for_table.py"
  output_path = "${local.lambda_path}/get_file_keys_for_table.zip"
}

module "get_file_keys_for_table" {
  source             = "./modules/lambdas"
  filename           = "${local.lambda_path}/get_file_keys_for_table.zip"
  function_name      = "get_file_keys_for_table"
  role_arn           = aws_iam_role.get_file_keys_for_table.arn
  role_name          = aws_iam_role.get_file_keys_for_table.name
  handler            = "get_file_keys_for_table.handler"
  source_code_hash   = data.archive_file.send_table_to_ap.output_base64sha256
  layers             = null
  timeout            = 900
  memory_size        = 1024
  runtime            = "python3.11"
  security_group_ids = [aws_security_group.lambda_db_security_group.id]
  subnet_ids         = data.aws_subnets.shared-public.ids
  env_account_id     = local.env_account_id
  environment_variables = {
    PARQUET_BUCKET_NAME = aws_s3_bucket.dms_target_ep_s3_bucket.id
  }
}



# ------------------------------------------------------
# Send table to AP 
# ------------------------------------------------------


data "archive_file" "send_table_to_ap" {
  type        = "zip"
  source_file = "${local.lambda_path}/send_table_to_ap.py"
  output_path = "${local.lambda_path}/send_table_to_ap.zip"
}

module "send_table_to_ap" {
  source             = "./modules/lambdas"
  filename           = "${local.lambda_path}/send_table_to_ap.zip"
  function_name      = "send_table_to_ap"
  role_arn           = aws_iam_role.send_table_to_ap.arn
  role_name          = aws_iam_role.send_table_to_ap.name
  handler            = "send_table_to_ap.handler"
  source_code_hash   = data.archive_file.send_table_to_ap.output_base64sha256
  layers             = null
  timeout            = 900
  memory_size        = 1024
  runtime            = "python3.11"
  security_group_ids = null
  subnet_ids         = null
  env_account_id     = local.env_account_id
  environment_variables = {
    AP_DESTINATION_BUCKET = local.land_bucket
  }
}

# ------------------------------------------------------
# Get Tables from DB
# ------------------------------------------------------


data "archive_file" "query_output_to_list" {
  type        = "zip"
  source_file = "${local.lambda_path}/query_output_to_list.py"
  output_path = "${local.lambda_path}/query_output_to_list.zip"
}

module "query_output_to_list" {
  source                = "./modules/lambdas"
  filename              = "${local.lambda_path}/query_output_to_list.zip"
  function_name         = "query_output_to_list"
  role_arn              = aws_iam_role.query_output_to_list.arn
  role_name             = aws_iam_role.query_output_to_list.name
  handler               = "query_output_to_list.handler"
  source_code_hash      = data.archive_file.query_output_to_list.output_base64sha256
  layers                = null
  timeout               = 900
  memory_size           = 1024
  runtime               = "python3.11"
  security_group_ids    = null
  subnet_ids            = null
  env_account_id        = local.env_account_id
  environment_variables = null
}

# ------------------------------------------------------
# Update log table
# ------------------------------------------------------

module "update_log_table" {
    source = "./modules/lambdas"
    function_name = "update_log_table"
    is_image = true
    role_name = aws_iam_role.update_log_table.name
    role_arn = aws_iam_role.update_log_table.arn
    memory_size = 1024
    timeout = 900
    env_account_id = local.env_account_id
    ecr_repo_name = module.ecr_lambdas_repo.repository_name
    ecr_repo_urk = module.ecr_lambdas_repo.repository_url
    environment_variables = {
      S3_LOG_BUCKET = aws_s3_bucket.dms_dv_parquet_s3_bucket.id
      DATABASE_NAME = aws_glue_catalog_database.dms_dv_glue_catalog_db.name
      TABLE_NAME = "glue_df_output"
      }
}

#-----------------------------------------------------------------------------------
# S3 lambda function to perform zip file structure extraction into json for Athena
#-----------------------------------------------------------------------------------

data "archive_file" "output_file_structure_as_json_from_zip" {
  type        = "zip"
  source_file = "${local.lambda_path}/${local.output_fs_json_lambda}.py"
  output_path = "${local.lambda_path}/${local.output_fs_json_lambda}.zip"
}

module "output_file_structure_as_json_from_zip" {
  source                = "./modules/lambdas"
  filename              = "${local.lambda_path}/${local.output_fs_json_lambda}.zip"
  function_name         = local.output_fs_json_lambda
  role_arn              = aws_iam_role.output_fs_json_lambda.arn
  role_name             = aws_iam_role.output_fs_json_lambda.name
  handler               = "${local.output_fs_json_lambda}.handler"
  source_code_hash      = data.archive_file.output_file_structure_as_json_from_zip.output_base64sha256
  layers                = ["arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPythonV2:67"]
  timeout               = 900
  memory_size           = 1024
  runtime               = "python3.12"
  security_group_ids    = [aws_security_group.lambda_db_security_group.id]
  subnet_ids            = data.aws_subnets.shared-public.ids
  env_account_id        = local.env_account_id
  environment_variables = null
}

