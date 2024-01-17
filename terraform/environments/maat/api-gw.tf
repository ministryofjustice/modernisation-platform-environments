# Variables
variable "pAppName" {}
variable "pApiScope1" {}
variable "pApiStageName" {}
variable "pAppApiGatewayFQDN" {}
variable "pAppCertificateArn" {}

# API Gateway configuration
resource "aws_apigatewayv2_vpc_link" "maat_api_gateway_vpc_link" {
  name             = "${local.application_name}_VPC_Link"
  security_group_ids = [aws_security_group.maat_api_gw_sg]
  subnet_ids        = [var.env-AppPrivateSubnetA, var.env-AppPrivateSubnetB, var.env-AppPrivateSubnetC]
}

resource "aws_logs_log_group" "maat_api_gateway_cloudwatch_log_group" {
  name = "${local.application_name}-API-Gateway"
  retention_in_days = 90
}

resource "aws_apigatewayv2_api" "maat_api_gateway" {
  name        = "${local.application_name} API Gateway"
  description = "${local.application_name} API Gateway - HTTP API"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "maat_api_integration" {
  api_id             = aws_apigatewayv2_api.maat_api_gateway.id
  description        = "${local.application_name} Integration Proxy"
  integration_type   = "HTTP_PROXY"
  integration_uri    = aws_lb_listener.maat_api_alb_http_listener.arn
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.maat_api_gateway_vpc_link.id
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "ApiRoute1" {
  api_id               = aws_apigatewayv2_api.maat_api_gateway.id
  route_key            = "ANY /link/validate"
  authorization_type   = "JWT"
  authorization_scopes = [local.application_name/var.pApiScope1]
  authorizer_id        = aws_apigatewayv2_authorizer.ApiAuthorizer.id
  target               = "/integrations/${aws_apigatewayv2_integration.ApiIntegration.id}"
  depends_on           = [aws_apigatewayv2_integration.ApiIntegration]
}

resource "aws_apigatewayv2_route" "ApiRouteCrimeMeansAssessment" {
  api_id               = aws_apigatewayv2_api.ApiGateway.id
  route_key            = "ANY /api/internal/v1/{proxy+}"
  authorization_type   = "JWT"
  authorization_scopes = [local.application_name/var.pApiScope1]
  authorizer_id        = aws_apigatewayv2_authorizer.ApiAuthorizer.id
  target               = "/integrations/${aws_apigatewayv2_integration.ApiIntegration.id}"
}

resource "aws_apigatewayv2_route" "ApiRouteCrownCourtProceeding" {
  api_id               = aws_apigatewayv2_api.ApiGateway.id
  route_key            = "ANY /api/internal/v1/crowncourtproceeding"
  authorization_type   = "JWT"
  authorization_scopes = [local.application_name/var.pApiScope1]
  authorizer_id        = aws_apigatewayv2_authorizer.ApiAuthorizer.id
  target               = "/integrations/${aws_apigatewayv2_integration.ApiIntegration.id}"
}

resource "aws_apigatewayv2_route" "ApiRouteEformStaging" {
  api_id               = aws_apigatewayv2_api.ApiGateway.id
  route_key            = "ANY /api/eform/{proxy+}"
  authorization_type   = "JWT"
  authorization_scopes = [local.application_name/var.pApiScope1]
  authorizer_id        = aws_apigatewayv2_authorizer.ApiAuthorizerForATSAndCAA.id
  target               = "/integrations/${aws_apigatewayv2_integration.ApiIntegration.id}"
}

resource "aws_apigatewayv2_route" "ApiRouteDCESService" {
  api_id               = aws_apigatewayv2_api.ApiGateway.id
  route_key            = "ANY /api/internal/v1/debt-collection-enforcement/{proxy+}"
  authorization_type   = "JWT"
  authorization_scopes = [local.application_name/var.pApiScope1]
  authorizer_id        = aws_apigatewayv2_authorizer.ApiAuthorizerForDces.id
  target               = "/integrations/${aws_apigatewayv2_integration.ApiIntegration.id}"
}

resource "aws_apigatewayv2_authorizer" "ApiAuthorizer" {
  name              = "${local.application_name}_Authorizer"
  api_id            = aws_apigatewayv2_api.ApiGateway.id
  authorizer_type   = "JWT"
  identity_sources   = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [
      var.CognitoUserPoolClient,
      var.CognitoUserPoolClientCda,
      var.CognitoUserPoolClientCrimeMeansAssessment,
      var.CognitoUserPoolClientCrownCourtProceeding,
      var.CognitoUserPoolClientCrownCourtContribution,
      var.CognitoUserPoolClientCrimeEvidence,
      var.CognitoUserPoolCrimeHardshipService,
      var.CognitoUserPoolMAATOrchestrationService,
      var.CognitoUserPoolClientCrimeValidationService,
    ]
    issuer   = aws_cognito_user_pool.ProviderURL
  }
}

resource "aws_apigatewayv2_authorizer" "ApiAuthorizerForDces" {
  name              = "${var.pAppName}_DCES_Authorizer"
  api_id            = aws_apigatewayv2_api.ApiGateway.id
  authorizer_type   = "JWT"


  jwt_configuration {
    audience = [
      var.CognitoUserPoolClientDcesReportService,
      var.CognitoUserPoolClientDcesDrcReportService,
    ]
    issuer   = aws_cognito_user_pool.ProviderURL
  }
}

resource "aws_apigatewayv2_authorizer" "ApiAuthorizerForATSAndCAA" {
  name              = "${var.pAppName}_ATS_And_CAA_Authorizer"
  api_id            = aws_apigatewayv2_api.ApiGateway.id
  authorizer_type   = "JWT"
  identity_sources   = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [
      var.CognitoUserPoolClientCrimeApplyAdaptor,
      var.CognitoUserPoolClientATSService,
    ]
    issuer   = aws_cognito_user_pool.ProviderURL
  }
}

resource "aws_apigatewayv2_stage" "ApiStage" {
  name = var.pApiStageName
  description = "${var.pAppName} ${var.pApiStageName} Stage"
  api_id     = aws_apigatewayv2_api.ApiGateway.id
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_logs_log_group.ApiGatewayCloudwatchLogGroup.arn
    format = "{\"requestId\":\"$context.requestId\",\"extendedRequestId\":\"$context.extendedRequestId\",\"ip\":\"$context.identity.sourceIp\",\"clientId\":\"$context.authorizer.claims.client_id\",\"requestTime\":\"$context.requestTime\",\"routeKey\":\"$context.routeKey\",\"status\":\"$context.status\"}"
  }
}

resource "aws_apigatewayv2_domain_name" "ApiExternalDomainName" {
  domain_name_configuration {
    endpoint_type = "Regional"
    certificate_arn = var.pAppCertificateArn
    certificate_name = "-"
  }
}

resource "aws_route53_record" "ApiExternalDNSRecord" {
  zone_id = data.aws_route53_zone.dns.HostedZoneId
  comment        = "Domain CNAME record for External Api Gateway"
  name           = var.pAppApiGatewayFQDN
  type           = "CNAME"
  ttl            = "60"
  records        = [aws_apigatewayv2_domain_name.ApiExternalDomainName.regional_domain_name]
}

resource "aws_apigatewayv2_api_mapping" "ApiMapping" {
  domain_name = aws_apigatewayv2_domain_name.ApiExternalDomainName.domain_name
  api_id      = aws_apigatewayv2_api.ApiGateway.id
  stage       = aws_apigatewayv2_stage.ApiStage.stage_name
  depends_on  = [aws_apigatewayv2_domain_name.ApiExternalDomainName]
}