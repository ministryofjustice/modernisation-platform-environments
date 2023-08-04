resource "aws_api_gateway_rest_api" "this" {
  name = "${var.name}-rest-gw"
  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = var.endpoint_ids
  }
}

resource "aws_api_gateway_resource" "this" {
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "domain"
  rest_api_id = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_resource" "preview" {
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "preview"
  rest_api_id = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method" "preview" {
  authorization = "NONE"
  http_method   = "ANY"
  resource_id   = aws_api_gateway_resource.preview.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_integration" "preview" {
  http_method             = aws_api_gateway_method.preview.http_method
  resource_id             = aws_api_gateway_resource.preview.id
  rest_api_id             = aws_api_gateway_rest_api.this.id
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_arn
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
  uri                     = var.lambda_arn
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
      aws_api_gateway_resource.preview.id,
      aws_api_gateway_method.preview.id,
      aws_api_gateway_integration.preview.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.this,
    aws_api_gateway_integration.this,
    aws_api_gateway_rest_api_policy.this,
    aws_api_gateway_method.preview,
    aws_api_gateway_integration.preview,
  ]
}

resource "aws_api_gateway_stage" "default_deployment" {
  deployment_id = aws_api_gateway_deployment.default_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "default"
}

resource "aws_api_gateway_rest_api_policy" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  policy      = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "execute-api:Invoke",
            "Resource": "${aws_api_gateway_rest_api.this.execution_arn}/*"
        }
    ]
}
EOF
}
