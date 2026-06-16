# Lambda

resource "aws_security_group" "rag_lambda" {
  name        = "${local.application_name}-${local.environment}-rag-lambda-security-group"
  description = "RAG Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    description = "outbound access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM role

resource "aws_iam_role" "rag_lambda_role" {
  name        = "RAGLambdaFunctionRole"
  description = "RAG Lambda Function IAM Role"

  assume_role_policy = data.aws_iam_policy_document.rag_lambda_function_assume_role.json

  tags = {
    "service-area" = "Hosting"
  }
}

resource "aws_iam_role_policy" "rag_lambda_policy" {
  name   = "rag_lambda_policy"
  role   = aws_iam_role.rag_lambda_role.id
  policy = data.aws_iam_policy_document.rag_lambda_function_role.json
}

data "aws_iam_policy_document" "rag_lambda_function_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "rag_lambda_function_role" {

  statement {
    sid    = "AllowToWriteCloudWatchLog"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/RAGLambdaFunction:*"]
  }

  statement {
    sid    = "AllowS3Access"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*"
    ]
  }

  statement {
    sid    = "AllowAthenaQueries"
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
    sid    = "AllowGlueCatalogRead"
    effect = "Allow"

    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowSecretsManager"
    effect = "Allow"

    actions = ["secretsmanager:GetSecretValue"]

    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:llm_gateway_key-USBFqg",
      "arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:llm_gateway_key-1biv4G"
    ]
  }

  statement {
    sid    = "AllowKMS"
    effect = "Allow"

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]

    resources = [
      "arn:aws:kms:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:key/ef7e1dc9-dc2b-4733-9278-46885b7040c7"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "rag_lambda_vpc_access" {
  role       = aws_iam_role.rag_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

module "rag_lambda" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_AWS_173:No sensitive information stored in Lambda environment variables
  #checkov:skip=CKV_AWS_116:Queue it self has DLQ so Lambda fail should redrive to DLQ
  #checkov:skip=CKV_AWS_272:Doesn't need code signing

  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name = "RAGLambdaFunction"
  description   = "Recieve NL request from user, use Bedrock to create SQL from NL, and use query to extract data from Athena"
  handler       = "rag-lambda.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30

  source_path = [{
    path = "${path.module}/lambdas/rag-lambda"
    commands = [
      "pip3 install -r requirements.txt -t .",
      ":zip",
    ]
  }]
  trigger_on_package_timestamp = false

  reserved_concurrent_executions = 10

  vpc_subnet_ids         = [data.aws_subnet.private_subnets_a.id]
  vpc_security_group_ids = [aws_security_group.rag_lambda.id]

  tracing_mode = "PassThrough"

  environment_variables = {
    ENVIRONMENT = local.environment
  }

  create_role = false
  lambda_role = aws_iam_role.rag_lambda_role.arn

  cloudwatch_logs_retention_in_days = 120

  tags = {
    "service-area" = "Hosting"
  }
}

moved {
  from = aws_lambda_function.rag_lambda
  to   = module.rag_lambda.aws_lambda_function.this[0]
}

moved {
  from = aws_cloudwatch_log_group.rag_lambda_log_group
  to   = module.rag_lambda.aws_cloudwatch_log_group.lambda[0]
}

# Secrets

resource "aws_secretsmanager_secret" "llm_gateway_key" {
  name = "llm_gateway_key"
}
