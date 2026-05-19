resource "aws_iam_role" "lambda_process_file_from_bucket_role" {
  name = "${local.application_name}-${local.environment}-lambda_process_file_from_bucket_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-lambda_process_file_from_bucket_role"
  })
}

resource "aws_iam_role_policy" "lambda_process_file_from_bucket_policy" {
  name = "${local.application_name}-${local.environment}-lambda_process_file_from_bucket_policy"
  role = aws_iam_role.lambda_process_file_from_bucket_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging"
        ]
        Resource = [
          module.s3-bucket-sftp-bc.bucket.arn,
          "${module.s3-bucket-sftp-bc.bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.process_file_from_bucket_lambda_function.function_name}:*"
      }
    ]
  })
}

resource "aws_lambda_function" "process_file_from_bucket_lambda_function" {
  filename      = "./lambda/process_file_from_bucket/target/HelloWorldHandler-1.0.jar"
  function_name = "${local.application_name}-${local.environment}-process-file-from-bucket-lambda-function"
  role          = aws_iam_role.lambda_process_file_from_bucket_role.arn
  handler       = "example.HelloWorldHandler"
  runtime       = "java21"
  timeout       = 30
  publish       = true

  vpc_config {
    security_group_ids = [aws_security_group.process_file_from_bucket_lambda_sg.id]
    subnet_ids         = data.aws_subnets.shared-private.ids
  }

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-process-file-from-bucket"
  })
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_file_from_bucket_lambda_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3-bucket-sftp-bc.bucket.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_process_file_from_bucket_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
