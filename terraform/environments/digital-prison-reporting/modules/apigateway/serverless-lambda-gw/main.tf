resource "aws_api_gateway_rest_api" "this" {
  name = "${var.name}-rest-gw"
  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = var.endpoint_ids
  }
}

resource "aws_api_gateway_resource" "this" {
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "/domain"
  rest_api_id = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method" "this" {
  authorization = "NONE"
  http_method   = "ANY"
  resource_id   = aws_api_gateway_resource.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_integration" "this" {
  http_method             = aws_api_gateway_method.this.http_method
  resource_id             = aws_api_gateway_resource.this.id
  rest_api_id             = aws_api_gateway_rest_api.this.id
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.this.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "default_deployment" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.this.id,
      aws_api_gateway_method.this.id,
      aws_api_gateway_integration.this.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "default_deployment" {
  deployment_id = aws_api_gateway_deployment.default_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "default"
}
