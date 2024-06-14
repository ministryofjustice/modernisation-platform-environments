# --------------------------------------------------------------------------------
# create_athena_external_tables IAM
# --------------------------------------------------------------------------------

resource "aws_iam_role" "create_athena_table_lambda" {
    name = "create_athena_table_lambda"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access_execution" {
    role = aws_iam_role.create_athena_table_lambda.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_queue_access_execution" {
    role = aws_iam_role.create_athena_table_lambda.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "get_glue_connections_and_tables" {
    role = aws_iam_role.create_athena_table_lambda.name
    policy_arn = aws_iam_policy.get_glue_connections_and_tables.arn
}

resource "aws_iam_policy" "get_glue_connections_and_tables" {
  name   = "get_glue_connections_and_tables"
  policy = data.aws_iam_policy_document.get_glue_connections_and_tables.json
}

resource "aws_iam_role_policy_attachment" "get_s3_output" {
    role = aws_iam_role.create_athena_table_lambda.name
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
            sid       = "TriggerLambda"
            effect    = "Allow"
            actions   = [
                "lambda:InvokeFunction"
            ]
            resources = [module.create_athena_table.lambda_function_arn]
        }
  statement {
    sid       = "GetGlueTables"
    effect    = "Allow"
    actions   = [
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
  name                = "send_table_to_ap"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "send_table_to_ap_lambda_vpc_access_execution" {
    role = aws_iam_role.send_table_to_ap.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "send_table_to_ap_lambda_sqs_queue_access_execution" {
    role = aws_iam_role.send_table_to_ap.name
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
    name = "get_parquet_files"
    policy = data.aws_iam_policy_document.get_parquet_files.json
}

resource "aws_iam_role_policy_attachment" "send_table_to_ap_get_parquet_files" {
    role = aws_iam_role.send_table_to_ap.name
    policy_arn = aws_iam_policy.get_parquet_files.arn
}

# ------------------------------------------------
# Get tables from db
# ------------------------------------------------

resource "aws_iam_role" "get_tables_from_db" {
    name                = "get_tables_from_db"
    assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "get_tables_from_db_lambda_vpc_access_execution" {
    role = aws_iam_role.get_tables_from_db.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "get_tables_from_db_lambda_sqs_queue_access_execution" {
    role = aws_iam_role.get_tables_from_db.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}




data "aws_iam_policy_document" "get_glue_tables" {
    statement {
        effect = "Allow"
        actions = [
            "glue:GetTable",
            "glue:GetTables",
            "glue:GetDatabase"
        ]
        resources = ["*"]
    }
}

resource "aws_iam_policy" "get_glue_tables" {
    name = "get_glue_tables"
    policy = data.aws_iam_policy_document.get_glue_tables.json
}

resource "aws_iam_role_policy_attachment" "get_tables_from_db_get_glue_tables" {
    role = aws_iam_role.get_tables_from_db.name
    policy_arn = aws_iam_policy.get_glue_tables.arn
}


# ------------------------------------------
# get_file_keys_for_table
# ------------------------------------------

resource "aws_iam_role" "get_file_keys_for_table" {
  name = "get_file_keys_for_table"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "get_file_keys_for_table_lambda_vpc_access_execution" {
    role = aws_iam_role.get_file_keys_for_table.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "get_file_keys_for_table_lambda_sqs_queue_access_execution" {
    role = aws_iam_role.get_file_keys_for_table.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

data "aws_iam_policy_document" "list_target_s3_bucket" {
  statement {
    effect = "Allow"
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.dms_target_ep_s3_bucket.arn]
  }
}

resource "aws_iam_policy" "list_target_s3_bucket" {
  name = "list_target_s3_bucket"
  policy = data.aws_iam_policy_document.list_target_s3_bucket.json
}
resource "aws_iam_role_policy_attachment" "get_file_keys_for_table_list_target_s3_bucket" {
    role = aws_iam_role.get_file_keys_for_table.name
    policy_arn = aws_iam_policy.list_target_s3_bucket.arn
}
