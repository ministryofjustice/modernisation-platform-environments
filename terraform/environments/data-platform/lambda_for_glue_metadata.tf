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

module "data_product_get_glue_metadata_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=v2.0.0"
  application_name               = "data_product_get_glue_metadata"
  tags                           = local.tags
  description                    = "Lambda to retrieve Glue metadata for a specified table in a database"
  role_name                      = "get_glue_metadata_lambda_role_${local.environment}"
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_get_glue_metadata_lambda
  function_name                  = "data_product_get_glue_metadata_${local.environment}"
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-get-glue-metadata-lambda-ecr-repo:1.0.0"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  allowed_triggers = {

    AllowExecutionFromAPIGateway = {
      action        = "lambda:InvokeFunction"
      function_name = "data_product_get_glue_metadata_${local.environment}"
      principal     = "apigateway.amazonaws.com"
      source_arn    = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/${aws_api_gateway_method.get_glue_metadata.http_method}${aws_api_gateway_resource.get_glue_metadata.path}"
    }
  }

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

  request_parameters = {
    "method.request.header.Authorization" = true,
    "method.request.querystring.database" = true,
    "method.request.querystring.table"    = true,
  }
}

resource "aws_api_gateway_integration" "get_glue_metadata" {
  http_method             = aws_api_gateway_method.get_glue_metadata.http_method
  resource_id             = aws_api_gateway_resource.get_glue_metadata.id
  rest_api_id             = aws_api_gateway_rest_api.data_platform.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_get_glue_metadata_lambda.lambda_function_arn

  request_parameters = {
    "integration.request.querystring.database" = "method.request.querystring.database",
    "integration.request.querystring.table"    = "method.request.querystring.table"
  }
}

output "get_glue_metadata_endpoint" {
  value = join("", [aws_api_gateway_deployment.deployment.invoke_url, aws_api_gateway_stage.sandbox.stage_name, "/get_glue_metadata/"])
}
