resource "aws_api_gateway_rest_api" "ingestion_api" {
  name = "${local.application_name}-api"
  tags = local.tags
}

resource "aws_api_gateway_resource" "ingest" {
  rest_api_id = aws_api_gateway_rest_api.ingestion_api.id
  parent_id   = aws_api_gateway_rest_api.ingestion_api.root_resource_id
  path_part   = "ingest"
}

resource "aws_api_gateway_authorizer" "hmac" {
  name            = "hmac-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.ingestion_api.id
  authorizer_uri  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.authorizer_lambda.lambda_function_arn}/invocations"
  type            = "REQUEST"
  identity_source = "method.request.header.X-Signature, method.request.header.Date"
}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.ingestion_api.id
  resource_id   = aws_api_gateway_resource.ingest.id
  http_method   = "POST"
  authorization = "NONE"
  request_parameters = {
    "method.request.header.X-Signature" = true
    "method.request.header.Date"        = true
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.ingestion_api.id
  resource_id = aws_api_gateway_resource.ingest.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.ingestion_api.id
  resource_id             = aws_api_gateway_resource.ingest.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"  
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.authorizer_lambda.lambda_function_arn}/invocations"
}

resource "aws_api_gateway_integration_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.ingestion_api.id
  resource_id = aws_api_gateway_resource.ingest.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "200"
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.ingestion_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_authorizer.hmac.id,
      aws_api_gateway_authorizer.hmac.type,
      aws_api_gateway_method.post.id
    ]))
  }

  depends_on = [
    aws_api_gateway_method.post,
    aws_api_gateway_authorizer.hmac
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.ingestion_api.id
  stage_name    = local.environment

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access_logs.arn
    format = jsonencode({
      extendedRequestId  = "$context.extendedRequestId"
      ip                 = "$context.identity.sourceIp"
      client             = "$context.identity.clientCert.subjectDN"
      issuerDN           = "$context.identity.clientCert.issuerDN"
      requestTime        = "$context.requestTime"
      httpMethod         = "$context.httpMethod"
      resourcePath       = "$context.resourcePath"
      status             = "$context.status"
      responseLength     = "$context.responseLength"
      error              = "$context.error.message"
      authenticateStatus = "$context.authenticate.status"
      authenticateError  = "$context.authenticate.error"
      integrationStatus  = "$context.integration.status"
      integrationError   = "$context.integration.error"
      apiKeyId           = "$context.identity.apiKeyId"
      authDecision       = "$context.authorizer.auth"
      authReason         = "$context.authorizer.reason"
    })
  }

  tags = local.tags
}

# Account-level Logging Role
module "apigw_cloudwatch_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.58.0"

  create_role = true

  role_name = "apigateway-cloudwatch-logs-role-${local.environment}"

  trusted_role_services = [
    "apigateway.amazonaws.com"
  ]

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  ]
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = module.apigw_cloudwatch_role.iam_role_arn
}

resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.ingestion_api.id}/${local.environment}"
  retention_in_days = 60
  tags              = local.tags
}

