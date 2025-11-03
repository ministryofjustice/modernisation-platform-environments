# IAM Role for Lambda@Edge
resource "aws_iam_role" "lambda_edge_role" {
  name = "CloudfrontRedirectLambdaRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
        }
      }
    ]
  })
}

# Create ZIP archive for Lambda@Edge function
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

# Lambda@Edge Function (must be in us-east-1 for CloudFront)
resource "aws_lambda_function" "cloudfront_redirect_lambda" {
  provider         = aws.us-east-1
  function_name    = "CloudfrontRedirectLambda"
  filename         = local.is-production ? data.archive_file.lambda_zip.output_path : data.archive_file.lambda_zip_nonprod.output_path
  source_code_hash = local.is-production ? data.archive_file.lambda_zip.output_base64sha256 : data.archive_file.lambda_zip_nonprod.output_base64sha256
  role             = aws_iam_role.lambda_edge_role.arn
  handler          = "cloudfront-redirect.handler"
  runtime          = "nodejs18.x"
  publish          = true
  timeout          = 5
  memory_size      = 128
}