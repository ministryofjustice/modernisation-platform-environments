data "archive_file" "get_glue_metadata_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/get_glue_metadata"
  output_path = "${path.module}/src/get_glue_metadata_${local.environment}/get_glue_metadata_lambda.zip"
}

resource "aws_iam_role" "get_glue_metadata_lambda_role" {
  name               = "get_glue_metadata_role_${local.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy_doc.json
  tags               = local.tags
}

data "aws_iam_policy_document" "iam_policy_document_for_get_glue_metadata_lambda" {
  statement {
    sid     = "GlueReadOnly"
    effect  = "Allow"
    actions = ["glue:GetTable", "glue:GetTables", "glue:GetDatabase", "glue:GetDatabases"]
    resources = [
      "arn:aws:glue:${local.region}:${local.account_id}:catalog",
      "arn:aws:glue:${local.region}:${local.account_id}:database/*",
      "arn:aws:glue:${local.region}:${local.account_id}:table/*"
    ]
  }
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/*"]
  }
}

resource "aws_iam_policy" "get_glue_metadata_lambda_policy" {
  name        = "get_glue_metadata_policy_${local.environment}"
  path        = "/"
  description = "AWS IAM Policy for managing get_glue_metadata lambda role"
  policy      = data.aws_iam_policy_document.iam_policy_document_for_get_glue_metadata_lambda.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "attach_get_glue_metadata_lambda_policy_to_iam_role" {
  role       = aws_iam_role.get_glue_metadata_lambda_role.name
  policy_arn = aws_iam_policy.get_glue_metadata_lambda_policy.arn
}

resource "aws_lambda_function" "get_glue_metadata" {
  function_name    = "get_glue_metadata_${local.environment}"
  description      = "api gateway get_glue_metadata"
  handler          = "main.handler"
  runtime          = local.lambda_runtime
  filename         = data.archive_file.get_glue_metadata_zip.output_path
  source_code_hash = data.archive_file.get_glue_metadata_zip.output_base64sha256
  role             = aws_iam_role.get_glue_metadata_lambda_role.arn
  depends_on       = [aws_iam_role_policy_attachment.attach_code_lambda_policy_to_iam_role]
  tags             = local.tags
}

resource "aws_lambda_permission" "get_glue_metadata" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_glue_metadata.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/${aws_api_gateway_method.get_glue_metadata.http_method}${aws_api_gateway_resource.get_glue_metadata.path}"
}

resource "aws_api_gateway_resource" "get_glue_metadata" {
  parent_id   = aws_api_gateway_rest_api.data_platform.root_resource_id
  path_part   = "get_glue_metadata"
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
}

resource "aws_api_gateway_method" "get_glue_metadata" {
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.get_glue_metadata.id
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id
}

resource "aws_api_gateway_integration" "get_glue_metadata" {
  http_method             = aws_api_gateway_method.get_glue_metadata.http_method
  resource_id             = aws_api_gateway_resource.get_glue_metadata.id
  rest_api_id             = aws_api_gateway_rest_api.data_platform.id
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_glue_metadata.invoke_arn
}

output "get_glue_metadata_endpoint" {
  value = join("", [aws_api_gateway_deployment.deployment.invoke_url, "/get_glue_metadata/"])
}
