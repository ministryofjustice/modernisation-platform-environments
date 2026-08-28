# Gateway infrastructure

resource "aws_api_gateway_rest_api" "chatbot_api" {
  #checkov:skip=CKV_AWS_237: "Ensure Create before destroy for API Gateway"
  name = "chatbot-${local.environment}-gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "send_request" {
  parent_id   = aws_api_gateway_rest_api.chatbot_api.root_resource_id
  path_part   = "send-request"
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
}

resource "aws_api_gateway_method" "send_request_post" {
  #checkov:skip=CKV_AWS_70:Ensure API gateway method has authorization or API key set
  #checkov:skip=CKV2_AWS_53: “Ignoring AWS API gateway request validatation"
  #checkov:skip=CKV_AWS_59: "Ensure there is no open access to back-end resources through API"

  authorization    = "NONE"
  http_method      = "POST"
  resource_id      = aws_api_gateway_resource.send_request.id
  rest_api_id      = aws_api_gateway_rest_api.chatbot_api.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "send_request_post_integration" {
  http_method             = aws_api_gateway_method.send_request_post.http_method
  resource_id             = aws_api_gateway_resource.send_request.id
  rest_api_id             = aws_api_gateway_rest_api.chatbot_api.id
  type                    = "AWS_PROXY"
  uri                     = module.rag_lambda.lambda_function_invoke_arn
  integration_http_method = "POST"
}

# OPTIONS method for CORS

resource "aws_api_gateway_method" "send_request_options" {
  #checkov:skip=CKV_AWS_70:Ensure API gateway method has authorization or API key set
  #checkov:skip=CKV2_AWS_53: “Ignoring AWS API gateway request validatation"
  #checkov:skip=CKV_AWS_59: "Ensure there is no open access to back-end resources through API"

  authorization = "NONE"
  http_method   = "OPTIONS"
  resource_id   = aws_api_gateway_resource.send_request.id
  rest_api_id   = aws_api_gateway_rest_api.chatbot_api.id
}

resource "aws_api_gateway_integration" "send_request_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  resource_id = aws_api_gateway_resource.send_request.id
  http_method = aws_api_gateway_method.send_request_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "send_request_options_method_response" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  resource_id = aws_api_gateway_resource.send_request.id
  http_method = aws_api_gateway_method.send_request_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "send_request_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  resource_id = aws_api_gateway_resource.send_request.id
  http_method = aws_api_gateway_method.send_request_options.http_method
  status_code = aws_api_gateway_method_response.send_request_options_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.send_request_options_integration
  ]
}

resource "aws_api_gateway_deployment" "chatbot_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.send_request.id,
      aws_api_gateway_method.send_request_post.id,
      aws_api_gateway_integration.send_request_post_integration.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_rest_api.chatbot_api,
    aws_api_gateway_method.send_request_post,
    aws_api_gateway_integration.send_request_post_integration,
    aws_api_gateway_method.send_request_options,
    aws_api_gateway_integration.send_request_options_integration,
    aws_api_gateway_method_response.send_request_options_method_response,
    aws_api_gateway_integration_response.send_request_options_integration_response
  ]
}

resource "aws_cloudwatch_log_group" "chatbot_api_access_logs" {
  #checkov:skip=CKV_AWS_158:Default AWS encryption is sufficient for chatbot access logs

  name              = "/aws/apigateway/chatbot-${local.environment}"
  retention_in_days = 365
}

resource "aws_iam_role" "chatbot_api_cloudwatch" {
  name = "chatbot-${local.environment}-apigw-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "chatbot_api_cloudwatch" {
  role       = aws_iam_role.chatbot_api_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "chatbot" {
  cloudwatch_role_arn = aws_iam_role.chatbot_api_cloudwatch.arn

  depends_on = [aws_iam_role_policy_attachment.chatbot_api_cloudwatch]
}

resource "aws_api_gateway_client_certificate" "chatbot" {
  description = "Client certificate for chatbot-${local.environment} API Gateway"
}

resource "aws_api_gateway_stage" "chatbot_api_stage" {
  #checkov:skip=CKV_AWS_120:Caching disabled - chatbot responses are dynamic per user question
  #checkov:skip=CKV2_AWS_77:Log4j protection implemented via AWSManagedRulesKnownBadInputsRuleSet in associated WAF

  deployment_id         = aws_api_gateway_deployment.chatbot_api_deployment.id
  rest_api_id           = aws_api_gateway_rest_api.chatbot_api.id
  stage_name            = local.environment
  xray_tracing_enabled  = true
  client_certificate_id = aws_api_gateway_client_certificate.chatbot.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.chatbot_api_access_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      apiKeyId       = "$context.identity.apiKeyId"
    })
  }

  depends_on = [aws_api_gateway_account.chatbot]
}

resource "aws_api_gateway_method_settings" "chatbot_api_stage" {
  #checkov:skip=CKV_AWS_225:Caching disabled - chatbot responses are dynamic per user question

  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  stage_name  = aws_api_gateway_stage.chatbot_api_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }

  depends_on = [aws_api_gateway_account.chatbot]
}

resource "aws_wafv2_web_acl" "chatbot_api" {
  name        = "chatbot-${local.environment}-api-waf"
  description = "WAF for chatbot API Gateway"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "chatbot-${local.environment}-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "chatbot-${local.environment}-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "chatbot-${local.environment}-api-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "chatbot_api" {
  resource_arn = aws_api_gateway_stage.chatbot_api_stage.arn
  web_acl_arn  = aws_wafv2_web_acl.chatbot_api.arn
}

resource "aws_cloudwatch_log_group" "chatbot_api_waf_logs" {
  #checkov:skip=CKV_AWS_158:Default AWS encryption is sufficient for WAF logs

  name              = "aws-waf-logs-chatbot-${local.environment}"
  retention_in_days = 365
}

resource "aws_wafv2_web_acl_logging_configuration" "chatbot_api" {
  resource_arn            = aws_wafv2_web_acl.chatbot_api.arn
  log_destination_configs = [aws_cloudwatch_log_group.chatbot_api_waf_logs.arn]
}

# Permissions

resource "aws_lambda_permission" "chatbot_api_lambda_permission" {
  #checkov:skip=CKV_AWS_364:Ensure that AWS Lambda function permissions delegated to AWS services are limited by SourceArn or SourceAccount
  #checkov:skip=CKV_AWS_301:Ensure that AWS Lambda function is not publicly accessible

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.rag_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chatbot_api.execution_arn}/*/*"
}

# API key and usage plan

resource "aws_api_gateway_api_key" "chatbot_api_key" {
  name = "chatbot-development-api-key"
}

resource "aws_api_gateway_usage_plan" "chatbot_api_usage_plan" {
  name = "chatbot-${local.environment}-api-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.chatbot_api.id
    stage  = aws_api_gateway_stage.chatbot_api_stage.stage_name
  }

  quota_settings {
    limit  = 100
    period = "DAY"
  }

  throttle_settings {
    rate_limit  = 5
    burst_limit = 5
  }
}

resource "aws_api_gateway_usage_plan_key" "chatbot_api_key_plan_association" {
  key_id        = aws_api_gateway_api_key.chatbot_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.chatbot_api_usage_plan.id
}