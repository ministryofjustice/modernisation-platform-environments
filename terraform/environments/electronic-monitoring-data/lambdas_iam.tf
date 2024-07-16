# --------------------------------------------------------------------------------
# create_athena_external_tables IAM
# --------------------------------------------------------------------------------

resource "aws_iam_role" "create_athena_table_lambda" {
  name               = "create_athena_table_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access_execution" {
  role       = aws_iam_role.create_athena_table_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_queue_access_execution" {
  role       = aws_iam_role.create_athena_table_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "get_glue_connections_and_tables" {
  role       = aws_iam_role.create_athena_table_lambda.name
  policy_arn = aws_iam_policy.get_glue_connections_and_tables.arn
}

resource "aws_iam_policy" "get_glue_connections_and_tables" {
  name   = "get_glue_connections_and_tables"
  policy = data.aws_iam_policy_document.get_glue_connections_and_tables.json
}

resource "aws_iam_role_policy_attachment" "get_s3_output" {
  role       = aws_iam_role.create_athena_table_lambda.name
  policy_arn = aws_iam_policy.get_s3_output.arn
}

resource "aws_iam_policy" "get_s3_output" {
  name   = "get_s3_output"
  policy = data.aws_iam_policy_document.get_s3_output.json
}


data "aws_iam_policy_document" "get_glue_connections_and_tables" {
  statement {
    sid       = "SecretsManagerDbCredentialsAccess"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret_version.db_glue_connection.arn]
  }
  statement {
    sid    = "TriggerLambda"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [module.create_athena_table.lambda_function_arn]
  }
  statement {
    sid    = "GetGlueTables"
    effect = "Allow"
    actions = [
      "glue:GetTables",
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateDatabase",
      "glue:DeleteDatabase"
    ]
    resources = [
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:table/*",
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:userDefinedFunction/*"

    ]
  }
}

data "aws_iam_policy_document" "get_s3_output" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListObjects"
    ]
    resources = [
      "${aws_s3_bucket.dms_target_ep_s3_bucket.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.dms_target_ep_s3_bucket.arn
    ]
  }
}


# ------------------------------------------------
# get metadata from rds
# ------------------------------------------------

resource "aws_iam_role" "get_metadata_from_rds" {
  name               = "get_metadata_from_rds_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "get_metadata_from_rds_lambda_vpc_access_execution" {
  role       = aws_iam_role.get_metadata_from_rds.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "get_metadata_from_rds_lambda_sqs_queue_access_execution" {
  role       = aws_iam_role.get_metadata_from_rds.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "get_metadata_from_rds_get_glue_connections_and_tables" {
  role       = aws_iam_role.get_metadata_from_rds.name
  policy_arn = aws_iam_policy.get_glue_connections_and_tables.arn
}

resource "aws_iam_role_policy_attachment" "get_metadata_from_rds_get_s3_output" {
  role       = aws_iam_role.get_metadata_from_rds.name
  policy_arn = aws_iam_policy.get_s3_output.arn
}

resource "aws_iam_role_policy_attachment" "get_metadata_from_rds_write_meta_to_s3" {
  role       = aws_iam_role.get_metadata_from_rds.name
  policy_arn = aws_iam_policy.write_meta_to_s3.arn
}

resource "aws_iam_policy" "write_meta_to_s3" {
  name   = "write_meta_to_s3"
  policy = data.aws_iam_policy_document.write_meta_to_s3.json
}

data "aws_iam_policy_document" "write_meta_to_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListObjects",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${module.metadata-s3-bucket.bucket.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      module.metadata-s3-bucket.bucket.arn
    ]
  }
}



# ------------------------------------------------
# Write Metadata to AP
# ------------------------------------------------

locals {
  metadata_ap_bucket = local.is-production ? "mojap-metadata-prod" : "mojap-metadata-dev"
}

resource "aws_iam_role" "send_metadata_to_ap" {
  name               = "send_metadata_to_ap"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "write_metadata_to_ap_lambda_vpc_access_execution" {
  role       = aws_iam_role.send_metadata_to_ap.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "write_metadata_to_ap_lambda_sqs_queue_access_execution" {
  role       = aws_iam_role.send_metadata_to_ap.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}


resource "aws_iam_role_policy_attachment" "write_metadata_to_ap_write_meta_to_s3" {
  role       = aws_iam_role.send_metadata_to_ap.name
  policy_arn = aws_iam_policy.get_meta_from_s3.arn
}

resource "aws_iam_policy" "get_meta_from_s3" {
  name   = "get_meta_from_s3"
  policy = data.aws_iam_policy_document.get_meta_from_s3.json
}

resource "aws_iam_policy" "write_to_ap_s3" {
  name   = "write_to_ap_s3"
  policy = data.aws_iam_policy_document.write_to_ap_s3.json
}

resource "aws_iam_role_policy_attachment" "write_metadata_to_ap_write_to_ap_s3" {
  role       = aws_iam_role.send_metadata_to_ap.name
  policy_arn = aws_iam_policy.write_to_ap_s3.arn
}

data "aws_iam_policy_document" "get_meta_from_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListObjects",
      "s3:GetObject"
    ]
    resources = [
      "${module.metadata-s3-bucket.bucket.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      module.metadata-s3-bucket.bucket.arn
    ]
  }
}

data "aws_iam_policy_document" "write_to_ap_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.metadata_ap_bucket}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::${local.metadata_ap_bucket}/electronic_monitoring/*"
    ]
  }
}

# ------------------------------------------
# Send table to AP
# ------------------------------------------

resource "aws_iam_role" "send_table_to_ap" {
  name               = "send_table_to_ap"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "send_table_to_ap_lambda_vpc_access_execution" {
  role       = aws_iam_role.send_table_to_ap.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "send_table_to_ap_lambda_sqs_queue_access_execution" {
  role       = aws_iam_role.send_table_to_ap.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}


locals {
  land_bucket = local.is-production ? "mojap-land" : "mojap-land-dev"
}

data "aws_iam_policy_document" "get_parquet_files" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.dms_target_ep_s3_bucket.arn,
      "${aws_s3_bucket.dms_target_ep_s3_bucket.arn}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.land_bucket}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::${local.land_bucket}/electronic_monitoring/load/*"
    ]
  }
}

resource "aws_iam_policy" "get_parquet_files" {
  name   = "get_parquet_files"
  policy = data.aws_iam_policy_document.get_parquet_files.json
}

resource "aws_iam_role_policy_attachment" "send_table_to_ap_get_parquet_files" {
  role       = aws_iam_role.send_table_to_ap.name
  policy_arn = aws_iam_policy.get_parquet_files.arn
}

# ------------------------------------------------
# Get tables from db
# ------------------------------------------------

resource "aws_iam_role" "query_output_to_list" {
  name               = "query_output_to_list"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "query_output_to_list_lambda_sqs_queue_access_execution" {
  role       = aws_iam_role.query_output_to_list.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}


# ------------------------------------------
# get_file_keys_for_table
# ------------------------------------------

resource "aws_iam_role" "get_file_keys_for_table" {
  name               = "get_file_keys_for_table"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "get_file_keys_for_table_lambda_vpc_access_execution" {
  role       = aws_iam_role.get_file_keys_for_table.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "get_file_keys_for_table_lambda_sqs_queue_access_execution" {
  role       = aws_iam_role.get_file_keys_for_table.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

data "aws_iam_policy_document" "list_target_s3_bucket" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.dms_target_ep_s3_bucket.arn]
  }
}

resource "aws_iam_policy" "list_target_s3_bucket" {
  name   = "list_target_s3_bucket"
  policy = data.aws_iam_policy_document.list_target_s3_bucket.json
}
resource "aws_iam_role_policy_attachment" "get_file_keys_for_table_list_target_s3_bucket" {
  role       = aws_iam_role.get_file_keys_for_table.name
  policy_arn = aws_iam_policy.list_target_s3_bucket.arn
}

# ------------------------------------------
# update_log_table
# ------------------------------------------

resource "aws_iam_role" "update_log_table" {
  name               = "update_log_table"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "update_log_table_lambda_sqs_queue_access_execution" {
  role       = aws_iam_role.update_log_table.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

data "aws_iam_policy_document" "get_log_s3_files" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:GetBucketLocation",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.dms_dv_parquet_s3_bucket.arn,
      "${aws_s3_bucket.dms_dv_parquet_s3_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "get_log_s3_files" {
  name   = "get_log_s3_files"
  policy = data.aws_iam_policy_document.get_log_s3_files.json
}
resource "aws_iam_role_policy_attachment" "update_log_table_get_log_s3_files" {
  role       = aws_iam_role.update_log_table.name
  policy_arn = aws_iam_policy.get_log_s3_files.arn
}


# ------------------------------------------
# output_file_structure_as_json_from_zip
# ------------------------------------------

resource "aws_iam_role" "extract_metadata_from_atrium_unstructured" {
  name                = "extract_metadata_from_atrium_unstructured"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

data "aws_iam_policy_document" "extract_metadata_from_atrium_unstructured_s3_policy_document" {
  statement {
    sid    = "S3PermissionsForUnzippingLambda"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.data_store.arn}/*",
      aws_s3_bucket.data_store.arn
    ]
  }
}

resource "aws_iam_policy" "extract_metadata_from_atrium_unstructured_s3_policy" {
  name        = "extract-metadata-from-atrium-unstructured-lambda-s3-policy"
  description = "Policy for Lambda to use S3 for extract_metadata_from_atrium_unstructured"
  policy      = data.aws_iam_policy_document.extract_metadata_from_atrium_unstructured_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "extract_metadata_from_atrium_unstructured_s3_policy_attachment" {
  role       = aws_iam_role.extract_metadata_from_atrium_unstructured.name
  policy_arn = aws_iam_policy.extract_metadata_from_atrium_unstructured_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "extract_metadata_from_atrium_unstructured_vpc_access_execution" {
  role       = aws_iam_role.extract_metadata_from_atrium_unstructured.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "extract_metadata_from_atrium_unstructured_sqs_queue_access_execution" {
  role       = aws_iam_role.extract_metadata_from_atrium_unstructured.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_lambda_permission" "s3_allow_output_file_structure_as_json_from_zip" {
  statement_id  = "AllowOutputFileStructureAsJsonFromZipExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.output_file_structure_as_json_from_zip.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_store.arn
}

# ------------------------------------------
# unzip_unstructured_files
# ------------------------------------------

resource "aws_iam_role" "unzip_unstructured_files" {
  name               = "unzip_unstructured_files"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "unzip_unstructured_files_lambda_sqs_queue_access_execution" {
  role       = aws_iam_role.unzip_unstructured_files.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "unzip_unstructured_files_lambda_vpc_access_execution" {
  role       = aws_iam_role.unzip_unstructured_files.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "get_put_zip_s3_files" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.data_store.arn,
      "${aws_s3_bucket.data_store.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      module.unzipped-s3-data-store.bucket.arn,
      "${module.unzipped-s3-data-store.bucket.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "get_put_zip_s3_files" {
  name   = "get_put_zip_s3_files"
  policy = data.aws_iam_policy_document.get_put_zip_s3_files.json
}
resource "aws_iam_role_policy_attachment" "unzip_unstructured_files_get_put_zip_s3_files" {
  role       = aws_iam_role.unzip_unstructured_files.name
  policy_arn = aws_iam_policy.get_put_zip_s3_files.arn
}

# ------------------------------------------
# load table from json to athena
# ------------------------------------------

resource "aws_iam_role" "load_json_into_athena" {
  name = "load_json_into_athena"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "athena.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

data "aws_iam_policy_document" "load_json_into_athena_s3_policy_document" {
  statement {
    sid    = "S3PermissionsForLoadingJsonIntoAthena"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${aws_s3_bucket.data_store.arn}/*",
      aws_s3_bucket.data_store.arn,
      "${module.athena-s3-bucket.bucket.arn}/*",
      module.athena-s3-bucket.bucket.arn,
      module.metadata-s3-bucket.bucket.arn,
      "${module.metadata-s3-bucket.bucket.arn}/*",
    ]
  }
  statement {
    sid    = "AthenaPermissionsForLoadingJsonIntoAthena"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "GluePermissionsForLoadingJsonIntoAthena"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateDatabase",
      "glue:DeleteDatabase",
      "glue:UpdateTable"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "load_json_into_athena" {
  name        = "load-json-into-athena-s3-policy"
  description = "Policy for Lambda to use S3 for lambda"
  policy      = data.aws_iam_policy_document.load_json_into_athena_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "load_json_into_athena_s3_policy_policy_attachment" {
  role       = aws_iam_role.load_json_into_athena.name
  policy_arn = aws_iam_policy.load_json_into_athena.arn
}

resource "aws_iam_role_policy_attachment" "load_json_into_athena_vpc_access_execution" {
  role       = aws_iam_role.load_json_into_athena.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "load_json_into_athena_lambda_sqs_queue_access_execution" {
  role       = aws_iam_role.load_json_into_athena.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

# ------------------------------------------
# extract_zip_to_parquet
# ------------------------------------------

resource "aws_iam_role" "extract_zip_to_parquet" {
  name                = "extract_zip_to_parquet"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

data "aws_iam_policy_document" "extract_zip_to_parquet_s3_policy_document" {
  statement {
    sid    = "S3PermissionsForUnzippingLambda"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.data_store.arn}/*",
      aws_s3_bucket.data_store.arn
    ]
  }
}

resource "aws_iam_policy" "extract_zip_to_parquet_s3_policy" {
  name        = "extract-zip-to-parquet-lambda-s3-policy"
  description = "Policy for Lambda to use S3 for extract_zip_to_parquet"
  policy      = data.aws_iam_policy_document.extract_zip_to_parquet_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "extract_zip_to_parquet_s3_policy_attachment" {
  role       = aws_iam_role.extract_zip_to_parquet.name
  policy_arn = aws_iam_policy.extract_zip_to_parquet_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "extract_zip_to_parquet_vpc_access_execution" {
  role       = aws_iam_role.extract_zip_to_parquet.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "extract_zip_to_parquet_sqs_queue_access_execution" {
  role       = aws_iam_role.extract_zip_to_parquet.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_lambda_permission" "s3_allow_extract_zip_to_parquet" {
  statement_id  = "AllowOutputFileStructureAsJsonFromZipExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.extract_zip_to_parquet.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_store.arn
}
