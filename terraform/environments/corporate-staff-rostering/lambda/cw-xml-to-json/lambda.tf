locals {
  null
}

resource "null_resource" "lambda_build" {
  triggers = {
    # TODO add path to python file
    lambda_py = filesha256(null)
    # TODO add path to requirements file
    requirements_py = filesha256(null)
  }

  provisioner "local-exec" {
    command = "bash build.sh"
  }
}

resource "aws_lambda_function" "cw_log_processor" {
  function_name = "CWXMLToJSON"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_handler" # Update based on your Lambda's language and handler
  runtime = "python3.11"
  filename      = "path/to/your/deployment/package.zip"

  source_code_hash = filebase64sha256("path/to/your/deployment/package.zip")
}

resource "aws_cloudwatch_log_subscription_filter" "log_subscription_filter" {
  name            = "log_processor_trigger"
  log_group_name  = aws_cloudwatch_log_group.source_log_group.name
  filter_pattern  = "" # TODO add filter pattern
  destination_arn = aws_lambda_function.log_processor.arn
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_log_processing_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_log_processing_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Effect = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
