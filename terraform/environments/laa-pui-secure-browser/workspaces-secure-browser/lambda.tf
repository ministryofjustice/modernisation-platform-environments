####################
# Lambda callback handler
####################

# Build Lambda layer with dependencies
resource "null_resource" "lambda_dependencies" {
  count = local.create_resources ? 1 : 0

  triggers = {
    requirements = filemd5("${path.module}/lambda/callback/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/.terraform/lambda_layer/python
      pip3 install -r ${path.module}/lambda/callback/requirements.txt -t ${path.module}/.terraform/lambda_layer/python --upgrade
    EOT
  }
}

data "archive_file" "lambda_layer_zip" {
  count      = local.create_resources ? 1 : 0
  depends_on = [null_resource.lambda_dependencies]

  type        = "zip"
  source_dir  = "${path.module}/.terraform/lambda_layer"
  output_path = "${path.module}/.terraform/lambda_layer.zip"
}

resource "aws_lambda_layer_version" "dependencies" {
  count = local.create_resources ? 1 : 0

  layer_name          = "${local.application_name}-callback-dependencies-${local.environment}"
  filename            = data.archive_file.lambda_layer_zip[0].output_path
  source_code_hash    = data.archive_file.lambda_layer_zip[0].output_base64sha256
  compatible_runtimes = ["python3.11"]

  description = "PyJWT and cryptography for OAuth callback handler"
}

data "archive_file" "callback_lambda_zip" {
  count = local.create_resources ? 1 : 0

  type        = "zip"
  source_dir  = "${path.module}/lambda/callback"
  output_path = "${path.module}/.terraform/lambda_callback.zip"
  excludes    = ["requirements.txt"]
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

# Policy to read Azure config from Secrets Manager
resource "aws_iam_role_policy" "callback_lambda_secrets" {
  count = local.create_resources ? 1 : 0

  name = "${local.application_name}-callback-lambda-secrets-${local.environment}"
  role = aws_iam_role.callback_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = data.aws_secretsmanager_secret.azure_entra_config[0].arn
      }
    ]
  })
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

  layers = [aws_lambda_layer_version.dependencies[0].arn]

  environment {
    variables = {
      PORTAL_URL          = "https://${aws_workspacesweb_portal.external["external_1"].portal_endpoint}"
      AZURE_TENANT_ID     = local.azure_config.tenant_id
      AZURE_CLIENT_ID     = local.azure_config.client_id
      AZURE_CLIENT_SECRET = local.azure_config.client_secret
      CALLBACK_URL        = "${aws_apigatewayv2_api.callback[0].api_endpoint}/callback"
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "callback-lambda"
    }
  )
}
