# tflint-ignore-file: terraform_required_version, terraform_required_providers

resource "aws_api_gateway_rest_api" "this" {
  #checkov:skip=CKV_AWS_237: "Ensure Create before destroy for API Gateway"
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
  #checkov:skip=CKV_AWS_70:Ensure API gateway method has authorization or API key set
  #checkov:skip=CKV2_AWS_53: “Ignoring AWS API gateway request validatation"
  #checkov:skip=CKV_AWS_59: "Ensure there is no open access to back-end resources through API"


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

resource "aws_api_gateway_resource" "publish" {
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "publish"
  rest_api_id = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_method" "publish" {
  #checkov:skip=CKV_AWS_70:Ensure API gateway method has authorization or API key set
  #checkov:skip=CKV2_AWS_53: “Ignoring AWS API gateway request validatation"
  #checkov:skip=CKV_AWS_59: "Ensure there is no open access to back-end resources through API"

  authorization = "NONE"
  http_method   = "ANY"
  resource_id   = aws_api_gateway_resource.publish.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_integration" "publish" {
  http_method             = aws_api_gateway_method.publish.http_method
  resource_id             = aws_api_gateway_resource.publish.id
  rest_api_id             = aws_api_gateway_rest_api.this.id
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_arn
}

resource "aws_api_gateway_method" "this" {
  #checkov:skip=CKV_AWS_70:Ensure API gateway method has authorization or API key set
  #checkov:skip=CKV2_AWS_53: “Ignoring AWS API gateway request validatation"
  #checkov:skip=CKV_AWS_59: "Ensure there is no open access to back-end resources through API"

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
  #checkov:skip=CKV_AWS_364:Ensure that AWS Lambda function permissions delegated to AWS services are limited by SourceArn or SourceAccount
  #checkov:skip=CKV_AWS_301:Ensure that AWS Lambda function is not publicly accessible

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "default_deployment" {
  #checkov:skip=CKV_AWS_217:Ensure Create before destroy for API deployments

  rest_api_id = aws_api_gateway_rest_api.this.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.this.id,
      aws_api_gateway_method.this.id,
      aws_api_gateway_integration.this.id,
      aws_api_gateway_resource.preview.id,
      aws_api_gateway_method.preview.id,
      aws_api_gateway_integration.preview.id,
      aws_api_gateway_resource.publish.id,
      aws_api_gateway_method.publish.id,
      aws_api_gateway_integration.publish.id,
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
    aws_api_gateway_method.publish,
    aws_api_gateway_integration.publish,
  ]
}

resource "aws_api_gateway_stage" "default_deployment" {
  #checkov:skip=CKV2_AWS_4: "Ignore - Ensure API Gateway stage have logging level defined as appropriate"
  #checkov:skip=CKV2_AWS_51: "Ignore - Ensure AWS API Gateway endpoints uses client certificate authentication"
  #checkov:skip=CKV_AWS_120: "Ensure API Gateway caching is enabled"
  #checkov:skip=CKV_AWS_73: "Ensure API Gateway has X-Ray Tracing enabled"
  #checkov:skip=CKV_AWS_76: "Ensure API Gateway has Access Logging enabled"
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
