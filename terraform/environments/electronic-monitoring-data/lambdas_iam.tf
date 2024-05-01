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
        effect = "Allow"
        actions = [
            "glue:GetConnection",
            "glue:GetTables"
        ]
        resources = ["*"]
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
}
