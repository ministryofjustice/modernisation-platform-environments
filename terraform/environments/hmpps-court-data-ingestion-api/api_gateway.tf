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
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.hmac.id
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

resource "aws_api_gateway_integration" "sqs" {
  rest_api_id             = aws_api_gateway_rest_api.ingestion_api.id
  resource_id             = aws_api_gateway_resource.ingest.id
  http_method             = aws_api_gateway_method.post.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  credentials             = module.apigw_sqs_role.iam_role_arn

  # SQS Path Integration: arn:aws:apigateway:{region}:sqs:path/{account_id}/{queue_name}
  # Account ID is retrieved from Secrets Manager (must be populated manually)
  uri = "arn:aws:apigateway:eu-west-2:sqs:path/${data.aws_secretsmanager_secret_version.cloud_platform_account_id.secret_string}/${local.environment_configuration[local.environment].cloud_platform_sqs_queue_name}"

  request_templates = {
    "application/json" = <<EOF
Action=SendMessage&MessageBody=$util.urlEncode($input.body)&MessageAttribute.1.Name=X-Signature&MessageAttribute.1.Value.StringValue=$util.escapeJavaScript($input.params('X-Signature'))&MessageAttribute.1.Value.DataType=String&MessageAttribute.2.Name=Date&MessageAttribute.2.Value.StringValue=$util.escapeJavaScript($input.params('Date'))&MessageAttribute.2.Value.DataType=String
EOF
  }
}

resource "aws_iam_role_policy" "apigw_sqs_policy" {
  role = module.apigw_sqs_role.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sqs:SendMessage"
      Resource = "arn:aws:sqs:eu-west-2:${data.aws_secretsmanager_secret_version.cloud_platform_account_id.secret_string}:${local.environment_configuration[local.environment].cloud_platform_sqs_queue_name}"
    }]
  })
}

resource "aws_api_gateway_integration_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.ingestion_api.id
  resource_id = aws_api_gateway_resource.ingest.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "200"

  depends_on = [aws_api_gateway_integration.sqs]
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.ingestion_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_authorizer.hmac.id,
      aws_api_gateway_authorizer.hmac.type,
      aws_api_gateway_method.post.id,
      aws_api_gateway_integration.sqs.id,
    ]))
  }

  depends_on = [
    aws_api_gateway_method.post,
    aws_api_gateway_integration.sqs
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

# IAM Role for API Gateway to push to SQS
module "apigw_sqs_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.58.0"

  create_role       = true
  role_requires_mfa = false

  role_name = "apigw-sqs-role-mp"

  trusted_role_services = [
    "apigateway.amazonaws.com"
  ]
}
