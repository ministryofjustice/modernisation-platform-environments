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
    # statement {
    #         sid       = "RDSDataServiceAccess"
    #         effect    = "Allow"
    #         actions   = [
    #             "rds-data:BatchExecuteStatement",
    #             "rds-data:BeginTransaction",
    #             "rds-data:CommitTransaction",
    #             "rds-data:ExecuteStatement",
    #             "rds-data:RollbackTransaction"
    #         ]
    #         resources = ["arn:aws:rds:eu-west-2:${data.aws_caller_identity.current.account_id}:cluster:prod"]
    #     }

    statement {
        effect = "Allow"
        actions = [
            "glue:GetConnection",
            "glue:GetTables",
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
            "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:table/${local.db_name}_semantic_layer/*"
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
