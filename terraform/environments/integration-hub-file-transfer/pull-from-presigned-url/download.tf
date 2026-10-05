resource "aws_apigatewayv2_api" "pickup" {
  name          = local.pattern_name
  protocol_type = "HTTP"
  tags          = local.tags
}

resource "aws_cloudwatch_log_group" "pickup_api" {
  name              = "/aws/apigateway/${local.pattern_name}"
  retention_in_days = 90
  kms_key_id        = data.aws_kms_key.logs.arn
  tags              = local.tags
}

resource "aws_apigatewayv2_stage" "pickup" {
  api_id      = aws_apigatewayv2_api.pickup.id
  name        = "$default"
  auto_deploy = true
  default_route_settings {
    throttling_burst_limit = 20
    throttling_rate_limit  = 10
  }
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.pickup_api.arn
    # No query strings, tokens, file paths or generated URLs in access logs.
    format = jsonencode({ requestId = "$context.requestId", status = "$context.status", route = "$context.routeKey" })
  }
  tags = local.tags
}

resource "aws_apigatewayv2_authorizer" "sso" {
  count            = local.pickup_sso == null ? 0 : 1
  api_id           = aws_apigatewayv2_api.pickup.id
  name             = "organisation-sso"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    audience = [local.pickup_sso.audience]
    issuer   = local.pickup_sso.issuer
  }
}

resource "aws_apigatewayv2_integration" "pickup" {
  api_id                 = aws_apigatewayv2_api.pickup.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda_download.lambda_function_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "page" {
  for_each  = toset(["GET /pickups/{id}", "GET /callback"])
  api_id    = aws_apigatewayv2_api.pickup.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.pickup.id}"
}

resource "aws_apigatewayv2_route" "download" {
  count                = local.pickup_sso == null ? 0 : 1
  api_id               = aws_apigatewayv2_api.pickup.id
  route_key            = "POST /pickups/{id}/download"
  target               = "integrations/${aws_apigatewayv2_integration.pickup.id}"
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.sso[0].id
  authorization_scopes = [local.pickup_sso.download_scope]
}

module "lambda_download" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "8.9.0"
  function_name                     = "${local.pattern_name}-download"
  role_name                         = "${local.pattern_name}-download"
  description                       = "Authorise a recipient and issue a five-minute URL for an exact retained object version"
  runtime                           = "python3.12"
  architectures                     = ["arm64"]
  handler                           = "handler.lambda_handler"
  source_path                       = [{ path = "${path.module}/lambda/download", patterns = ["!tests/.*", "!.*__pycache__/.*"] }]
  timeout                           = 15
  memory_size                       = 256
  cloudwatch_logs_retention_in_days = 90
  cloudwatch_logs_kms_key_id        = data.aws_kms_key.logs.arn
  attach_tracing_policy             = true
  tracing_mode                      = "Active"
  environment_variables = {
    PICKUP_TABLE = module.dynamodb_notifications.dynamodb_table_id
    CONFIG = jsonencode({
      sso           = local.pickup_sso
      portal_url    = local.portal_url
      pickup_bucket = module.s3_pickup.s3_bucket_id
      recipients    = local.recipients
    })
  }
  create_current_version_allowed_triggers = false
  allowed_triggers = {
    gateway = {
      principal  = "apigateway.amazonaws.com"
      source_arn = "${aws_apigatewayv2_api.pickup.execution_arn}/*"
    }
  }
  attach_policy_statements = true
  policy_statements = {
    receipts = {
      actions   = ["dynamodb:GetItem"]
      resources = [module.dynamodb_notifications.dynamodb_table_arn]
    }
    exact_versions = {
      actions   = ["s3:GetObjectVersion"]
      resources = ["${module.s3_pickup.s3_bucket_arn}/*"]
    }
    decrypt = {
      actions   = ["kms:Decrypt"]
      resources = [module.kms_notifications_pipeline.key_arn]
    }
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "download_errors" {
  alarm_name          = "${local.pattern_name}-download-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  dimensions          = { FunctionName = module.lambda_download.lambda_function_name }
  tags                = local.tags
}
output "sso_callback_url" { value = "${local.portal_url}/callback" }
