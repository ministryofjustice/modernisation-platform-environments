####################
# Lambda callback handler
####################
data "archive_file" "callback_lambda_zip" {
  count = local.create_resources ? 1 : 0

  type        = "zip"
  source_dir  = "${path.module}/lambda/callback"
  output_path = "${path.module}/.terraform/lambda_callback.zip"
}

resource "aws_iam_role" "callback_lambda_role" {
  count = local.create_resources ? 1 : 0

  name = "${local.application_name}-callback-lambda-role-${local.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "callback_lambda_basic" {
  count = local.create_resources ? 1 : 0

  role       = aws_iam_role.callback_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "callback" {
  count = local.create_resources ? 1 : 0

  function_name    = "${local.application_name}-callback-lambda-${local.environment}"
  filename         = data.archive_file.callback_lambda_zip[0].output_path
  source_code_hash = data.archive_file.callback_lambda_zip[0].output_base64sha256
  handler          = "handler.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.callback_lambda_role[0].arn
  timeout          = 10

  environment {
    variables = {
      PORTAL_URL = "https://${aws_workspacesweb_portal.external["external_1"].portal_endpoint}"
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "callback-lambda"
    }
  )
}
