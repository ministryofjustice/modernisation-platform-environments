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

  authorization = "NONE"
  http_method   = "ANY"
  resource_id   = aws_api_gateway_resource.send_request.id
  rest_api_id   = aws_api_gateway_rest_api.chatbot_api.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "send_request_post_integration" {
  http_method = aws_api_gateway_method.send_request_post.http_method
  resource_id = aws_api_gateway_resource.send_request.id
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  type = "AWS_PROXY"
  uri = aws_lambda_function.rag_lambda.invoke_arn
  http_method   = "POST"
}

# OPTIONS method for CORS

resource "aws_api_gateway_method" "send_request_options" {
  #checkov:skip=CKV_AWS_70:Ensure API gateway method has authorization or API key set
  #checkov:skip=CKV2_AWS_53: “Ignoring AWS API gateway request validatation"
  #checkov:skip=CKV_AWS_59: "Ensure there is no open access to back-end resources through API"

  authorization = "NONE"
  http_method   = "ANY"
  resource_id   = aws_api_gateway_resource.send_request.id
  rest_api_id   = aws_api_gateway_rest_api.chatbot_api.id
}

resource "aws_api_gateway_integration" "send_request_options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.chatbot_api.id
  resource_id             = aws_api_gateway_resource.send_request.id
  http_method             = aws_api_gateway_method.send_request_options.http_method
  type                    = "MOCK"
  http_method             = "OPTIONS"

  request_templates       = {
    "application/json" = "{\"statusCode\": 200}"
  }

  integration_http_method = "OPTIONS"
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
}

resource "aws_api_gateway_deployment" "chatbot_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id

  triggers = {
    redeployment = sha1(jsonencode([
        aws_api_gateway_resource.send_request.id,
        aws_api_gateway_method.send_request_post.id,
        aws_api_gateway_integration.send_request_post_integration.id,
        aws_api_gateway_method.send_request_options.id,
        aws_api_gateway_integration.send_request_options_integration.id,
        aws_api_gateway_method_response.send_request_options_method_response.id,
        aws_api_gateway_integration_response.send_request_options_integration_response.id
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

resource "aws_api_gateway_stage" "chatbot_api_stage" {
  deployment_id = aws_api_gateway_deployment.chatbot_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.chatbot_api.id
  stage_name    = local.environment
}

# Permissions

resource "aws_lambda_permission" "chatbot_api_lambda_permission" {
  #checkov:skip=CKV_AWS_364:Ensure that AWS Lambda function permissions delegated to AWS services are limited by SourceArn or SourceAccount
  #checkov:skip=CKV_AWS_301:Ensure that AWS Lambda function is not publicly accessible

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rag_lambda.function_name
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
    rate_limit = 5
  }
}

resource "aws_api_gateway_usage_plan_key" "chatbot_api_key_plan_association" {
  key_id        = aws_api_gateway_api_key.chatbot_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.chatbot_api_usage_plan.id
}
