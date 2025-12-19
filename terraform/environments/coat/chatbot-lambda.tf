# Lambda

resource "null_resource" "build_lambda_zip" {

  triggers = {
    script_hash = filesha256("${path.module}/lambdas/rag-lambda/rag-lambda.py")
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/lambdas/rag-lambda

      pip3 install -r requirements.txt

      zip -r rag-lambda.zip .
    EOT
  }
}

data "archive_file" "rag_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/rag-lambda/"
  output_path = "${path.module}/lambdas/rag-lambda.zip"
}

resource "aws_lambda_function" "rag_lambda" {
  #checkov:skip=CKV_AWS_173:No sensitive information stored in Lambda environment variables
  #checkov:skip=CKV_AWS_117:This Lambda doesn't need VPC
  #checkov:skip=CKV_AWS_116:Queue it self has DLQ so Lambda fail should redrive to DLQ
  #checkov:skip=CKV_AWS_272:Doesn't need code signing
  
  function_name = "RAGLambdaFunction"
  description   = "Recieve NL request from user, use Bedrock to create SQL from NL, and use query to extract data from Athena"

  role    = aws_iam_role.rag_lambda_role.arn
  runtime = "python3.12"
  timeout = 30 

  handler          = "rag-lambda.lambda_handler"
  package_type     = "Zip"
  filename         = "${path.module}/lambdas/rag-lambda/rag-lambda.zip"
  source_code_hash = data.archive_file.rag_lambda.output_base64sha256

  reserved_concurrent_executions = 10

  tracing_config {
    mode = "PassThrough"
  }

  tags = local.tags

  depends_on = [null_resource.build_lambda_zip]
}

# Logs

resource "aws_cloudwatch_log_group" "rag_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.rag_lambda.function_name}"
  retention_in_days = 120
}

# IAM role

resource "aws_iam_role" "rag_lambda_role" {
  name        = "RAGLambdaFunctionRole"
  description = "RAG Lambda Function IAM Role"

  assume_role_policy = data.aws_iam_policy_document.rag_lambda_function_assume_role.json

  inline_policy {
    name   = "rag_lambda_policy"
    policy = data.aws_iam_policy_document.rag_lambda_function_role.json
  }

  tags = local.tags
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
            "s3:ListBucket"
        ]

        resources = [
            "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/",
            "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*",
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

        resources = ["arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:llm_gateway_key"]
    }
}

# Secrets

resource "aws_secretsmanager_secret" "llm_gateway_key" {
  name = "llm_gateway_key"
}