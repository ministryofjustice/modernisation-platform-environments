moved {
  from = aws_cloudwatch_log_group.api_access
  to   = module.api_access_log_group.aws_cloudwatch_log_group.this[0]
}

moved {
  from = aws_apigatewayv2_api.upload_ticket
  to   = module.api_gateway.aws_apigatewayv2_api.this[0]
}

moved {
  from = aws_apigatewayv2_authorizer.mft_request
  to   = module.api_gateway.aws_apigatewayv2_authorizer.this["mft_request"]
}