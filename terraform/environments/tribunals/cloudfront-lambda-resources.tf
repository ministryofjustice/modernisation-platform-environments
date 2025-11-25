###############################
# Lambda@Edge – ONLY for HTTP distribution
###############################

# -------------------------------------------------
# 1. IAM Role
# -------------------------------------------------
resource "aws_iam_role" "lambda_edge_role" {
  name = "cloudfront_redirect_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_logging_policy" {
  name = "cloudfront_redirect_lambda_logs"
  role = aws_iam_role.lambda_edge_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/CloudfrontRedirectLambda:*"
      }
    ]
  })
}



# -------------------------------------------------
# 3. ZIP Archives (prod / non-prod)
# -------------------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda/cloudfront-redirect.js"
  output_path = "lambda/cloudfront-redirect.zip"
}

data "archive_file" "lambda_zip_nonprod" {
  type        = "zip"
  source_file = "lambda/cloudfront-redirect-nonprod.js"
  output_path = "lambda/cloudfront-redirect-nonprod.zip"
}

# -------------------------------------------------
# 4. Lambda@Edge Function
# -------------------------------------------------
resource "aws_lambda_function" "cloudfront_redirect_lambda" {
  # checkov:skip=CKV_AWS_50: X-Ray tracing is not supported for Lambda@Edge functions.
  # checkov:skip=CKV_AWS_115: Reserved concurrency cannot be configured for Lambda@Edge functions.
  # checkov:skip=CKV_AWS_116: Lambda@Edge is invoked synchronously by CloudFront and cannot use a DLQ.
  # checkov:skip=CKV_AWS_117: Lambda@Edge cannot be deployed inside a VPC.
  # checkov:skip=CKV_AWS_272: Code signing is not supported for Lambda@Edge functions.
  provider         = aws.us-east-1
  function_name    = "CloudfrontRedirectLambda"
  filename         = local.is-production ? data.archive_file.lambda_zip.output_path : data.archive_file.lambda_zip_nonprod.output_path
  source_code_hash = local.is-production ? filebase64sha256(data.archive_file.lambda_zip.source_file) : filebase64sha256(data.archive_file.lambda_zip_nonprod.source_file)
  handler          = local.is-production ? "cloudfront-redirect.handler" : "cloudfront-redirect-nonprod.handler"
  role             = aws_iam_role.lambda_edge_role.arn
  runtime          = "nodejs20.x"
  publish          = true
  timeout          = 5
  memory_size      = 128

  tags = {
    Name        = "cloudfront_redirect_lambda"
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "allow_http_cloudfront" {
  provider      = aws.us-east-1
  statement_id  = "AllowHttpCloudFrontExecution-${aws_lambda_function.cloudfront_redirect_lambda.version}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudfront_redirect_lambda.function_name
  principal     = "edgelambda.amazonaws.com"
  # Only set source_arn if distribution exists
  source_arn = (
    local.cloudfront_distribution_id != null ?
    "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${local.cloudfront_distribution_id}" :
    null
  )
  qualifier = aws_lambda_function.cloudfront_redirect_lambda.version
}

#Lambda@Edge replicator permission cannot have source_arn; intentional
#tfsec:ignore:AVD-AWS-0067
resource "aws_lambda_permission" "allow_replicator" {
  provider      = aws.us-east-1
  statement_id  = "AllowReplication-${aws_lambda_function.cloudfront_redirect_lambda.version}"
  action        = "lambda:GetFunction"
  function_name = aws_lambda_function.cloudfront_redirect_lambda.function_name
  principal     = "replicator.lambda.amazonaws.com"
  qualifier     = aws_lambda_function.cloudfront_redirect_lambda.version
}

