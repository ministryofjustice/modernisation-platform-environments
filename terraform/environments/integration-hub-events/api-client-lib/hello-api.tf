module "hello" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.13.0"

  architectures                     = ["arm64"]
  cloudwatch_logs_retention_in_days = 90
  description                       = "Replies Hello <path> to GET /<path>"
  function_name                     = "${local.application_name}-hello-public"
  handler                           = "handler.lambda_handler"
  ignore_source_code_hash           = true
  memory_size                       = 128
  runtime                           = "python3.12"
  timeout                           = 5
  source_path = [{
    path = "${path.module}/lambda/hello"
    patterns = [
      "!(.*/)?__pycache__(/.*)?$",
      "!(.*/)?[^/]+\\.pyc$",
    ]
  }]

  create_current_version_allowed_triggers = false

  tags = local.tags
}

# A separate API from the events API, so its routes cannot clash with it.
module "hello_api" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for pinned versions
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "6.1.0"

  name          = "${local.application_name}-hello-public"
  protocol_type = "HTTP"
  region        = data.aws_region.current.region

  create_domain_name             = false
  create_routes_and_integrations = false
  create_stage                   = false

  tags = local.tags
}

resource "aws_lambda_permission" "hello" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.hello.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.hello_api.api_execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "hello" {
  api_id                 = module.hello_api.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.hello.lambda_function_arn
  payload_format_version = "2.0"
}

# Deliberately public: it returns only a greeting and touches no data.
resource "aws_apigatewayv2_route" "hello" {
  #checkov:skip=CKV_AWS_309:The hello API is intentionally public
  api_id             = module.hello_api.api_id
  route_key          = "GET /{name}"
  target             = "integrations/${aws_apigatewayv2_integration.hello.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_stage" "hello" {
  api_id      = module.hello_api.api_id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    # Omitted limits in this block are sent as zero by the provider, blocking requests.
    throttling_rate_limit  = 10
    throttling_burst_limit = 20
  }

  tags = local.tags
}
