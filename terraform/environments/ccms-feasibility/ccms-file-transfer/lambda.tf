# Process File From Bucket Lambda: picks up files in the BC inbound folder and posts them to the Financial Transfers API

resource "aws_iam_role" "process_file_lambda" {
  name = "${local.component_name}-${local.env_label}-process-file-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-process-file-lambda-role"
  })
}

resource "aws_iam_role_policy" "process_file_lambda" {
  name = "${local.component_name}-${local.env_label}-process-file-lambda-policy"
  role = aws_iam_role.process_file_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:DeleteObject",
        ]
        Resource = [
          module.s3_bc_inbound.bucket.arn,
          "${module.s3_bc_inbound.bucket.arn}/*",
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.process_file_from_bucket.function_name}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret", "secretsmanager:ListSecretVersionIds"]
        Resource = aws_secretsmanager_secret.process_file_lambda.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:GenerateDataKey*", "kms:Decrypt"]
        Resource = aws_kms_key.fin_transfer.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "process_file_lambda_vpc" {
  role       = aws_iam_role.process_file_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "process_file_from_bucket" {
  # Placeholder package shared with ccms-ebs/ccms-file-transfer; the real code is deployed outside Terraform
  filename      = "${path.module}/../../ccms-ebs/ccms-file-transfer/lambda/process_file_from_bucket/target/HelloWorldHandler-1.0.jar"
  function_name = "${local.component_name}-${local.env_label}-process-file-from-bucket"
  role          = aws_iam_role.process_file_lambda.arn
  handler       = "example.HelloWorldHandler"
  runtime       = "java25"
  timeout       = 60
  publish       = true

  vpc_config {
    security_group_ids = [aws_security_group.process_file_lambda.id]
    subnet_ids         = data.aws_subnets.shared-private.ids
  }

  environment {
    variables = {
      SECRET_NAME        = aws_secretsmanager_secret.process_file_lambda.arn
      BUCKET_BASE_PREFIX = local.bc_bucket_base_path
    }
  }

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-process-file-from-bucket"
  })

  lifecycle {
    ignore_changes = [source_code_hash, filename, handler]
  }
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_file_from_bucket.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_bc_inbound.bucket.arn
}
