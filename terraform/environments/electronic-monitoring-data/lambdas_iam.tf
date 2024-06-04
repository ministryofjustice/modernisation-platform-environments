# --------------------------------------------------------------------------------
# create_athena_external_tables IAM
# --------------------------------------------------------------------------------

resource "aws_iam_role" "create_athena_external_tables_lambda" {
    name = "create_athena_external_tables_lambda"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access_execution" {
    role = aws_iam_role.create_athena_external_tables_lambda.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_queue_access_execution" {
    role = aws_iam_role.create_athena_external_tables_lambda.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "get_glue_connections_and_tables" {
    role = aws_iam_role.create_athena_external_tables_lambda.name
    policy_arn = aws_iam_policy.get_glue_connections_and_tables.arn
}

resource "aws_iam_policy" "get_glue_connections_and_tables" {
    name = "get_glue_connections_and_tables"
    policy = data.aws_iam_policy_document.get_glue_connections_and_tables.json
}

resource "aws_iam_role_policy_attachment" "get_s3_output" {
    role = aws_iam_role.create_athena_external_tables_lambda.name
    policy_arn = aws_iam_policy.get_s3_output.arn
}

resource "aws_iam_policy" "get_s3_output" {
    name = "get_s3_output"
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
            resources = [module.create_athena_external_table.lambda_function_arn]
        }

    statement {
        effect = "Allow"
        actions = [
            "glue:GetConnection",
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
            "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:database/${local.db_name}_semantic_layer",
            "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:table/${local.db_name}_semantic_layer/*",
            "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:userDefinedFunction/${local.db_name}_semantic_layer/*"

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
    name = "get_metadata_from_rds_lambda"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
    depends_on = [
        aws_iam_role_policy_attachment.get_metadata_from_rds_lambda_vpc_access_execution,
        aws_iam_role_policy_attachment.get_metadata_from_rds_lambda_sqs_queue_access_execution,
        aws_iam_role_policy_attachment.get_metadata_from_rds_get_glue_connections_and_tables,
        aws_iam_role_policy_attachment.get_metadata_from_rds_get_s3_output,
        aws_iam_role_policy_attachment.get_metadata_from_rds_write_meta_to_s3
    ]

}

resource "aws_iam_role_policy_attachment" "get_metadata_from_rds_lambda_vpc_access_execution" {
    role = aws_iam_role.get_metadata_from_rds.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "get_metadata_from_rds_lambda_sqs_queue_access_execution" {
    role = aws_iam_role.get_metadata_from_rds.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "get_metadata_from_rds_get_glue_connections_and_tables" {
    role = aws_iam_role.get_metadata_from_rds.name
    policy_arn = aws_iam_policy.get_glue_connections_and_tables.arn
}

resource "aws_iam_role_policy_attachment" "get_metadata_from_rds_get_s3_output" {
    role = aws_iam_role.get_metadata_from_rds.name
    policy_arn = aws_iam_policy.get_s3_output.arn
}

resource "aws_iam_role_policy_attachment" "get_metadata_from_rds_write_meta_to_s3" {
    role = aws_iam_role.get_metadata_from_rds.name
    policy_arn = aws_iam_policy.write_meta_to_s3.arn
}

resource "aws_iam_policy" "write_meta_to_s3" {
    name = "write_meta_to_s3"
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

resource "aws_iam_role" "send_metadata_to_ap" {
    name = "send_metadata_to_ap"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
    depends_on = [ 
        aws_iam_role_policy_attachment.write_metadata_to_ap_lambda_vpc_access_execution,
        aws_iam_role_policy_attachment.write_metadata_to_ap_lambda_sqs_queue_access_execution,
        aws_iam_role_policy_attachment.write_metadata_to_ap_write_meta_to_s3,
        aws_iam_role_policy_attachment.write_metadata_to_ap_write_to_ap_s3
     ]

}

resource "aws_iam_role_policy_attachment" "write_metadata_to_ap_lambda_vpc_access_execution" {
    role = aws_iam_role.send_metadata_to_ap.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "write_metadata_to_ap_lambda_sqs_queue_access_execution" {
    role = aws_iam_role.send_metadata_to_ap.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}


resource "aws_iam_role_policy_attachment" "write_metadata_to_ap_write_meta_to_s3" {
    role = aws_iam_role.send_metadata_to_ap.name
    policy_arn = aws_iam_policy.get_meta_from_s3.arn
}

resource "aws_iam_policy" "get_meta_from_s3" {
    name = "get_meta_from_s3"
    policy = data.aws_iam_policy_document.get_meta_from_s3.json
}

resource "aws_iam_policy" "write_to_ap_s3" {
    name = "write_to_ap_s3"
    policy = data.aws_iam_policy_document.write_to_ap_s3.json
}

resource "aws_iam_role_policy_attachment" "write_metadata_to_ap_write_to_ap_s3" {
    role = aws_iam_role.send_metadata_to_ap.name
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
      "arn:aws:s3:::moj-reg-${local.register_my_data_bucket_suffix}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::moj-reg-${local.register_my_data_bucket_suffix}/landing/electronic-monitoring-metadata/data/*"
    ]
  }
}