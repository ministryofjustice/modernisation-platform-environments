data "archive_file" "bootstrap" {
  type = "zip"

  source_file = "${path.module}/bootstrap/lambda_function.py"
  output_path = "${path.module}/bootstrap/lambda_function.zip"
}

data "aws_iam_policy_document" "bootstrap_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bootstrap" {
  name_prefix = "dms-core-bootstrap-"

  assume_role_policy = data.aws_iam_policy_document.bootstrap_assume_role.json

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-bootstrap"
      Purpose = "DMS integration test bootstrap"
    }
  )
}

data "aws_iam_policy_document" "bootstrap" {
  statement {
    sid    = "ReadRDSMasterSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_db_instance.postgres.master_user_secret[0].secret_arn
    ]
  }

  statement {
    sid    = "WriteDMSSourceSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:PutSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.dms_source.arn
    ]
  }
}

resource "aws_iam_role_policy" "bootstrap" {
  name_prefix = "dms-core-bootstrap-"
  role        = aws_iam_role.bootstrap.id

  policy = data.aws_iam_policy_document.bootstrap.json
}

resource "aws_iam_role_policy_attachment" "bootstrap_logs" {
  role       = aws_iam_role.bootstrap.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "bootstrap" {
  # checkov:skip=CKV_AWS_50: X-Ray tracing is not required for this manually invoked development integration-test bootstrap.
  # checkov:skip=CKV_AWS_116: A DLQ is not required because this Lambda is invoked synchronously and is not event-driven.
  # checkov:skip=CKV_AWS_117: VPC attachment is not required because this bootstrap only calls AWS APIs and does not connect directly to the private RDS instance.
  # checkov:skip=CKV_AWS_272: Code signing is not required for this temporary development integration-test Lambda.

  function_name = "${var.name}-bootstrap"

  role    = aws_iam_role.bootstrap.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"

  kms_key_arn = var.kms_key_arn

  filename         = data.archive_file.bootstrap.output_path
  source_code_hash = data.archive_file.bootstrap.output_base64sha256

  timeout                        = 30
  memory_size                    = 128
  reserved_concurrent_executions = 1

  environment {
    variables = {
      RDS_SECRET_ARN = aws_db_instance.postgres.master_user_secret[0].secret_arn
      DMS_SECRET_ARN = aws_secretsmanager_secret.dms_source.arn
      DB_HOST        = aws_db_instance.postgres.address
      DB_PORT        = tostring(aws_db_instance.postgres.port)
    }
  }

  depends_on = [
    aws_iam_role_policy.bootstrap,
    aws_iam_role_policy_attachment.bootstrap_logs
  ]

  tags = merge(
    var.tags,
    {
      Name    = "${var.name}-bootstrap"
      Purpose = "DMS integration test bootstrap"
    }
  )
}