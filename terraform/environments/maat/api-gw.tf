# # Variables
# locals {
#   maat_api_api_scope = local.application_data.accounts[local.environment].maat_api_api_scope
#   api_stage_name     = "v1"
# }

# # API Gateway configuration
# resource "aws_apigatewayv2_vpc_link" "maat_api_gateway_vpc_link" {
#   name               = "${local.application_name}_VPC_Link"
#   security_group_ids = [aws_security_group.maat_api_gw_sg.id]
#   subnet_ids         = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
# }

# resource "aws_cloudwatch_log_group" "maat_api_gateway_cloudwatch_log_group" {
#   name              = "${local.application_name}-API-Gateway"
#   retention_in_days = 90
# }

# resource "aws_apigatewayv2_api" "maat_api_gateway" {
#   name          = "${local.application_name} API Gateway"
#   description   = "${local.application_name} API Gateway - HTTP API"
#   protocol_type = "HTTP"
# }

# resource "aws_apigatewayv2_integration" "maat_api_integration" {
#   api_id                 = aws_apigatewayv2_api.maat_api_gateway.id
#   description            = "${local.application_name} Integration Proxy"
#   integration_type       = "HTTP_PROXY"
#   integration_uri        = aws_lb_listener.maat_api_alb_http_listener.arn
#   integration_method     = "ANY"
#   connection_type        = "VPC_LINK"
#   connection_id          = aws_apigatewayv2_vpc_link.maat_api_gateway_vpc_link.id
#   payload_format_version = "1.0"
# }

# resource "aws_apigatewayv2_route" "maat_api_route1" {
#   api_id               = aws_apigatewayv2_api.maat_api_gateway.id
#   route_key            = "ANY /link/validate"
#   authorization_type   = "JWT"
#   authorization_scopes = ["${local.application_name}/${local.maat_api_api_scope}"]
#   authorizer_id        = aws_apigatewayv2_authorizer.maat_api_authorizer.id
#   target               = "integrations/${aws_apigatewayv2_integration.maat_api_integration.id}"
#   depends_on           = [aws_apigatewayv2_integration.maat_api_integration]
# }

# resource "aws_apigatewayv2_route" "maat_api_route_crime_means_assessment" {
#   api_id               = aws_apigatewayv2_api.maat_api_gateway.id
#   route_key            = "ANY /api/internal/v1/{proxy+}"
#   authorization_type   = "JWT"
#   authorization_scopes = ["${local.application_name}/${local.maat_api_api_scope}"]
#   authorizer_id        = aws_apigatewayv2_authorizer.maat_api_authorizer.id
#   target               = "integrations/${aws_apigatewayv2_integration.maat_api_integration.id}"
# }

# resource "aws_apigatewayv2_route" "maat_api_route_eform_staging" {
#   api_id               = aws_apigatewayv2_api.maat_api_gateway.id
#   route_key            = "ANY /api/eform/{proxy+}"
#   authorization_type   = "JWT"
#   authorization_scopes = ["${local.application_name}/${local.maat_api_api_scope}"]
#   authorizer_id        = aws_apigatewayv2_authorizer.maat_api_authorizer_for_ats_and_caa.id
#   target               = "integrations/${aws_apigatewayv2_integration.maat_api_integration.id}"
# }

# resource "aws_apigatewayv2_route" "maat_api_route_dces_service" {
#   api_id               = aws_apigatewayv2_api.maat_api_gateway.id
#   route_key            = "ANY /api/internal/v1/debt-collection-enforcement/{proxy+}"
#   authorization_type   = "JWT"
#   authorization_scopes = ["${local.application_name}/${local.maat_api_api_scope}"]
#   authorizer_id        = aws_apigatewayv2_authorizer.maat_api_authorizer_for_dces.id
#   target               = "integrations/${aws_apigatewayv2_integration.maat_api_integration.id}"
# }

# resource "aws_apigatewayv2_authorizer" "maat_api_authorizer" {
#   name             = "${local.application_name}_Authorizer"
#   api_id           = aws_apigatewayv2_api.maat_api_gateway.id
#   authorizer_type  = "JWT"
#   identity_sources = ["$request.header.Authorization"]

#   jwt_configuration {
#     audience = [
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_default.id,
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_cda.id,
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_cma.id,
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_ccp.id,
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_ccc.id,
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_ce.id,
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_chs.id,
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_maatos.id,
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_cvs.id,
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_cccd.id
#     ]
#     issuer = "https://${aws_cognito_user_pool.maat_api_cognito_user_pool.endpoint}"
#   }
# }

# resource "aws_apigatewayv2_authorizer" "maat_api_authorizer_for_dces" {
#   name             = "${local.application_name}_DCES_Authorizer"
#   api_id           = aws_apigatewayv2_api.maat_api_gateway.id
#   identity_sources = ["$request.header.Authorization"]
#   authorizer_type  = "JWT"


#   jwt_configuration {
#     audience = [
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_dcrs.id,
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_dirs.id
#     ]
#     issuer = "https://${aws_cognito_user_pool.maat_api_cognito_user_pool.endpoint}"
#   }
# }

# resource "aws_apigatewayv2_authorizer" "maat_api_authorizer_for_ats_and_caa" {
#   name             = "${local.application_name}_ATS_And_CAA_Authorizer"
#   api_id           = aws_apigatewayv2_api.maat_api_gateway.id
#   authorizer_type  = "JWT"
#   identity_sources = ["$request.header.Authorization"]

#   jwt_configuration {
#     audience = [
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_caa.id,
#       aws_cognito_user_pool_client.maat_api_cognito_pool_client_ats.id
#     ]
#     issuer = "https://${aws_cognito_user_pool.maat_api_cognito_user_pool.endpoint}"
#   }
# }

# resource "aws_apigatewayv2_stage" "maat_api_stage" {
#   name        = local.api_stage_name
#   description = "${local.application_name} ${local.api_stage_name} Stage"
#   api_id      = aws_apigatewayv2_api.maat_api_gateway.id
#   auto_deploy = true

#   access_log_settings {
#     destination_arn = aws_cloudwatch_log_group.maat_api_gateway_cloudwatch_log_group.arn
#     format          = "{\"requestId\":\"$context.requestId\",\"extendedRequestId\":\"$context.extendedRequestId\",\"ip\":\"$context.identity.sourceIp\",\"clientId\":\"$context.authorizer.claims.client_id\",\"requestTime\":\"$context.requestTime\",\"routeKey\":\"$context.routeKey\",\"status\":\"$context.status\"}"
#   }
# }

# resource "aws_apigatewayv2_domain_name" "maat_api_external_domain_name" {
#   domain_name = "maat-cd-api-gateway.${data.aws_route53_zone.external.name}"
#   domain_name_configuration {
#     endpoint_type   = "REGIONAL"
#     certificate_arn = aws_acm_certificate.maat_api_acm_certificate.arn
#     security_policy = "TLS_1_2"
#   }
#   depends_on = [aws_acm_certificate.maat_api_acm_certificate]
# }

# resource "aws_acm_certificate" "maat_api_acm_certificate" {
#   domain_name               = "modernisation-platform.service.justice.gov.uk"
#   validation_method         = "DNS"
#   subject_alternative_names = local.environment == "production" ? null : ["maat-cd-api-gateway.${data.aws_route53_zone.external.name}"]
#   # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
#   # lifecycle {
#   #   prevent_destroy = false
#   # }
# }

# resource "aws_route53_record" "external_validation" {
#   provider = aws.core-network-services

#   count           = local.environment == "production" ? 0 : 1
#   allow_overwrite = true
#   name            = local.maat_api_domain_name_main[0]
#   records         = local.maat_api_domain_record_main
#   ttl             = 60
#   type            = local.maat_api_domain_type_main[0]
#   zone_id         = data.aws_route53_zone.network-services.zone_id
# }

# resource "aws_route53_record" "external_validation_subdomain" {
#   provider = aws.core-vpc

#   count           = local.environment == "production" ? 0 : 1
#   allow_overwrite = true
#   name            = local.maat_api_domain_name_sub[0]
#   records         = local.maat_api_domain_record_sub
#   ttl             = 60
#   type            = local.maat_api_domain_type_sub[0]
#   zone_id         = data.aws_route53_zone.external.zone_id
# }

# resource "aws_acm_certificate_validation" "maat_api_acm_certificate_validation" {
#   certificate_arn         = aws_acm_certificate.maat_api_acm_certificate.arn
#   validation_record_fqdns = [local.maat_api_domain_name_main[0], local.maat_api_domain_name_sub[0]]
# }

# resource "aws_apigatewayv2_api_mapping" "maat_api_mapping" {
#   domain_name = aws_apigatewayv2_domain_name.maat_api_external_domain_name.domain_name
#   api_id      = aws_apigatewayv2_api.maat_api_gateway.id
#   stage       = aws_apigatewayv2_stage.maat_api_stage.id
# }