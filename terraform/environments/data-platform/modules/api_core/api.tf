resource "aws_api_gateway_rest_api" "data_platform" {
  name = "data_platform-${var.environment}"
}

resource "aws_api_gateway_authorizer" "authorizer" {
  name                   = "authorizer-${var.environment}"
  rest_api_id            = aws_api_gateway_rest_api.data_platform.id
  authorizer_uri         = module.data_product_authorizer_lambda.lambda_function_invoke_arn
  authorizer_credentials = aws_iam_role.authoriser_role.arn
  identity_source        = "method.request.header.authorizationToken"
}
