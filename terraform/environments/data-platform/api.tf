resource "aws_api_gateway_rest_api" "data_platform" {
  name = "data_platform"
}

resource "aws_api_gateway_resource" "upload_data" {
  parent_id   = aws_api_gateway_rest_api.data_platform.root_resource_id
  path_part   = "upload_data"
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
}

resource "aws_api_gateway_method" "upload_data_get" {
  authorization = "CUSTOM"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.upload_data.id
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id
}

resource "aws_api_gateway_integration" "example" {
  http_method = aws_api_gateway_method.upload_data_get.http_method
  resource_id = aws_api_gateway_resource.upload_data.id
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  type        = "MOCK"
}

resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id

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
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id
  stage_name    = "example"
}

resource "aws_api_gateway_authorizer" "authorizer" {
  name                   = "authorizer-${local.environment}"
  rest_api_id            = aws_api_gateway_rest_api.data_platform.id
  authorizer_uri         = aws_lambda_function.authoriser.invoke_arn
  authorizer_credentials = aws_iam_role.authoriser_lambda_role.arn
}
