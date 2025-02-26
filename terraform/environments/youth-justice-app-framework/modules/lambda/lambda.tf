# Lambda function resource
resource "aws_lambda_function" "main" {
  function_name = var.lambda.function_name
  runtime       = "python3.12"
  handler       = var.lambda.handler
  role          = aws_iam_role.lambda_iam_roles.arn
  filename      = var.lambda.function_zip_file
  environment {
    variables = var.lambda.environment_variables
  }

  memory_size = 128
  timeout     = 10
}

resource "aws_iam_role" "lambda_iam_roles" {
  name               = var.lambda_role.name
  assume_role_policy = file(var.lambda_role.trust_policy_path)
}

resource "aws_iam_policy" "lambda_iam_permissions" {
  name   = var.lambda_role.name
  policy = templatefile(var.lambda_role.iam_policy_path, var.lambda_role.policy_template_vars)
}

resource "aws_iam_role_policy_attachment" "lambda_iam_roles_policy" {
  role       = aws_iam_role.lambda_iam_roles.name
  policy_arn = aws_iam_policy.lambda_iam_permissions.arn
}

resource "aws_iam_role_policy_attachment" "lambda_iam_roles_basic_policy" {
  role       = aws_iam_role.lambda_iam_roles.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

