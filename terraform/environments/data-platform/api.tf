# resource "aws_api_gateway_rest_api" "data_platform" {
#   name          = "data_platform"
#   protocol_type = "HTTP"
#   tags = local.tags
# }

# resource "aws_apigatewayv2_stage" "api_gateway_stage" {
#   api_id = aws_api_gateway_rest_api.data_platform.id

#   name        = local.environment
#   auto_deploy = true

#   access_log_settings {
#     destination_arn = aws_cloudwatch_log_group.api_gw.arn

#     format = jsonencode({
#       requestId               = "$context.requestId"
#       sourceIp                = "$context.identity.sourceIp"
#       requestTime             = "$context.requestTime"
#       protocol                = "$context.protocol"
#       httpMethod              = "$context.httpMethod"
#       resourcePath            = "$context.resourcePath"
#       routeKey                = "$context.routeKey"
#       status                  = "$context.status"
#       responseLength          = "$context.responseLength"
#       integrationErrorMessage = "$context.integrationErrorMessage"
#       }
#     )
#   }
# }

# resource "aws_apigatewayv2_integration" "presigned_url" {
#   api_id = aws_api_gateway_rest_api.data_platform.id

#   integration_uri    = aws_lambda_function.presigned_url.invoke_arn
#   integration_type   = "AWS_PROXY"
#   integration_method = "GET"
# }

# resource "aws_apigatewayv2_route" "presigned_url" {
#   api_id = aws_api_gateway_rest_api.data_platform.id

#   route_key = "GET /upload_data"
#   target    = "integrations/${aws_apigatewayv2_integration.presigned_url.id}"
# }

# resource "aws_cloudwatch_log_group" "api_gw" {
#   name = "/aws/api_gw/${aws_api_gateway_rest_api.data_platform.name}"

#   retention_in_days = 30
# }

resource "aws_api_gateway_rest_api" "example" {
  name = "example"
}

resource "aws_api_gateway_resource" "example" {
  parent_id   = aws_api_gateway_rest_api.example.root_resource_id
  path_part   = "example"
  rest_api_id = aws_api_gateway_rest_api.example.id
}

resource "aws_api_gateway_method" "example" {
  authorization = aws_api_gateway_authorizer.authorizer.id
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.example.id
  rest_api_id   = aws_api_gateway_rest_api.example.id
}

resource "aws_api_gateway_integration" "example" {
  http_method = aws_api_gateway_method.example.http_method
  resource_id = aws_api_gateway_resource.example.id
  rest_api_id = aws_api_gateway_rest_api.example.id
  type        = "MOCK"
}

resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.example.id,
      aws_api_gateway_method.example.id,
      aws_api_gateway_integration.example.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.example.id
  stage_name    = "example"
}

resource "aws_api_gateway_authorizer" "authorizer" {
  name                   = "authorizer-${local.environment}"
  rest_api_id            = aws_api_gateway_rest_api.example.id
  authorizer_uri         = aws_lambda_function.authoriser.invoke_arn
  authorizer_credentials = aws_iam_role.authoriser_lambda_role.arn
}
