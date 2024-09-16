# The S3 Buckets used for Staging DMS Replication data have non-deterministic names since
# these must be unique within AWS.  It is not straightforward to get the name of the S3
# bucket to use as a DMS Endpoint since it will exist in a different account to the local
# account.  To workaround this situation, we create a Lambda function which lists all S3
# buckets in a given account and accepts an IAM Role to use which have ListAllBuckets
# privileges in that account.   We can therefore call this Lambda function to list
# all the buckets in the target account (either client or repository) and filter those
# by the known prefix for the DMS staging bucket.

# The Lambda function is written in Python; create a ZIP file containing the Python to upload
data "archive_file" "list_buckets_zip" {
  type = "zip"
  source_file = "files/list_buckets.py"
  output_path = "files/list_buckets.zip"
}

# Upload Lambda deployment package to S3.  We use source_hash to force recreation of
# the Zip should the underlying Python source code change.
resource "aws_s3_object" "lambda_zip" {
  bucket        = module.s3_bucket_dms_destination.bucket.bucket
  key           = "list_buckets.zip"
  source        = data.archive_file.list_buckets_zip.output_path
  # Calculate Source Hash to force replacement if the zip file changes
  source_hash   = data.archive_file.list_buckets_zip.output_base64sha256
  depends_on    = [data.archive_file.list_buckets_zip]
}

# Create Lambda Function using uploaded Zip.  We use source_code_hash
# to force recreation of the function should there be a change to the Zip file.
resource "aws_lambda_function" "list_s3_buckets" {
  function_name    = "list_buckets"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "list_buckets.lambda_handler"
  runtime          = "python3.8"

  # Lambda deployment package location
  s3_bucket        = module.s3_bucket_dms_destination.bucket.bucket
  s3_key           = aws_s3_object.lambda_zip.key
   # Calculate the source_code_hash to force function replacement on package change
  source_code_hash = try(filebase64sha256("files/list_buckets.zip"),0)
  timeout          = 30
  depends_on       = [data.archive_file.list_buckets_zip]
}

# Create an API Gateway REST API.  This is used to allow Terraform to call the
# Lambda function to get the list of buckets.
resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "S3ListLambdaAPI"
  description = "API Gateway for listing S3 buckets via Lambda"
}

# Provide permission for the API Gateway to invoke our Lambda function.
resource "aws_lambda_permission" "apigateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_s3_buckets.function_name
  principal     = "apigateway.amazonaws.com"

  # Set the source ARN to the specific API Gateway REST API and stage
  source_arn = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*"
}

# Create a resource in the API Gateway.  We set path_part to "buckets"
# as this is for the bucket listing function.
resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "buckets"
}

# Create a method to invoke the Lambda function.  We use the GET method
# to allow us to include the target AWS Account ID and IAM Role in the request.
resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integrate API Gateway with Lambda.  Note that the integration must use
# the POST method even though the gateway method uses GET
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

# Add logs for debug purposes
resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
  name              = "/aws/apigateway/access-logs"
  retention_in_days = 30 
}

# We must define a stage for the API Gateway.  We set this to "prod"
# since we are only using one stage.
resource "aws_api_gateway_stage" "api_stage" {
  stage_name    = "prod"
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access_logs.arn
    format          = "$context.identity.sourceIp - $context.identity.caller [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId"
  }

  depends_on = [
    aws_api_gateway_account.api_gateway_account
  ]
}

# Additional setting for the API Gateway method call logging.
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

# Associate the IAM Role with API Gateway Account Settings for CloudWatch logging
resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn
}

# Use Terraform http data source to call the API and get repository bucket names
data "http" "get_buckets_lambda_output" {
  for_each   = local.bucket_list_target_map
  url        = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.eu-west-2.amazonaws.com/prod/buckets?target_account_id=${each.value}&target_environment_name=${each.key}"
  depends_on = [aws_api_gateway_deployment.api_deployment]
}
