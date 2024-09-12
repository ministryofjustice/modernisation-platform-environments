# Upload Lambda deployment package to S3
resource "aws_s3_object" "lambda_zip" {
  bucket = module.s3_bucket_dms_destination.bucket.bucket
  key    = "list_buckets.zip"
  source = "files/list_buckets.zip"
  # Calculate Etag to force replacement if the zip file changes
  etag   = filemd5("files/list_buckets.zip")
}

# Create Lambda Function
resource "aws_lambda_function" "list_s3_buckets" {
  function_name    = "list_buckets"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "list_buckets.lambda_handler"
  runtime          = "python3.8"

  # Lambda deployment package location
  s3_bucket        = module.s3_bucket_dms_destination.bucket.bucket
  s3_key           = aws_s3_object.lambda_zip.key
   # Calculate the source_code_hash to force function replacement on package change
  source_code_hash = filebase64sha256("files/list_buckets.zip")
  timeout          = 30
}

# Create an API Gateway REST API
resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "S3ListLambdaAPI"
  description = "API Gateway for listing S3 buckets via Lambda"
}

# Create a resource in the API Gateway
resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "buckets"
}

# Create a method to invoke the Lambda function
resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integrate API Gateway with Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.get_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_s3_buckets.invoke_arn
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  depends_on = [
        aws_api_gateway_method.get_method,
        aws_api_gateway_integration.lambda_integration
      ]
}


resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
  name              = "/aws/apigateway/access-logs"
  retention_in_days = 30  # Set retention as needed
}

resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = "prod"
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access_logs.arn
    format          = "$context.identity.sourceIp - $context.identity.caller [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId"
  }
}

resource "aws_api_gateway_method_settings" "api_stage_settings" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "*/*"

  settings {
    logging_level         = "INFO"   
    metrics_enabled       = true
    data_trace_enabled    = true
  }
}

# Use Terraform http data source to call the API and get bucket names
data "http" "lambda_output" {
  url = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.eu-west-2.amazonaws.com/prod/buckets"
}