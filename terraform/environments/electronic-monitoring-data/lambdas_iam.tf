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

resource "aws_iam_role_policy_attachment" "get_glue_connections" {
    role = aws_iam_role.create_athena_external_tables_lambda.name
    policy_arn = aws_iam_policy.get_glue_connections.arn
}

resource "aws_iam_policy" "get_glue_connections" {
    name = "get_glue_connections"
    policy = data.aws_iam_policy_document.get_glue_connections.json
}

data "aws_iam_policy_document" "get_glue_connections" {
    statement {
        effect = "Allow"
        actions = [
            "glue:GetConnection"
        ]
        resources = ["*"]
    }
}
