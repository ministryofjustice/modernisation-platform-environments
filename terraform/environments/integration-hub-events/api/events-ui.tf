module "events_ui" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.13.0"

  architectures                     = ["arm64"]
  cloudwatch_logs_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_logs_retention_in_days = 90
  description                       = "Serves the events UI and the API behind it"
  function_name                     = "${local.application_name}-events-ui"
  handler                           = "handler.lambda_handler"
  ignore_source_code_hash           = true
  memory_size                       = 256
  runtime                           = "python3.12"
  timeout                           = 15
  source_path = [{
    path = "${path.module}/lambda/events-ui"
    patterns = [
      "!(.*/)?__pycache__(/.*)?$",
      "!(.*/)?[^/]+\\.pyc$",
    ]
  }]

  environment_variables = {
    TABLE_NAME = module.events_db.dynamodb_table_id
  }

  attach_policy_statements = true
  policy_statements = {
    events_table = {
      effect = "Allow"
      actions = [
        "dynamodb:PutItem",
        "dynamodb:Scan",
        "dynamodb:UpdateItem",
      ]
      resources = [module.events_db.dynamodb_table_arn]
    }
  }

  create_current_version_allowed_triggers = false

  tags = local.tags
}

resource "aws_lambda_permission" "events_ui" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.events_ui.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "events_ui" {
  api_id                 = module.api_gateway.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.events_ui.lambda_function_arn
  payload_format_version = "2.0"
}

# Authentication is deliberately not configured yet, as for the publish route.
resource "aws_apigatewayv2_route" "events_ui" {
  #checkov:skip=CKV_AWS_309:Authorisation is deferred until the first version has been validated in development
  for_each = toset(["GET /", "GET /api/events", "POST /api/events"])

  api_id             = module.api_gateway.api_id
  route_key          = each.value
  target             = "integrations/${aws_apigatewayv2_integration.events_ui.id}"
  authorization_type = "NONE"
}
