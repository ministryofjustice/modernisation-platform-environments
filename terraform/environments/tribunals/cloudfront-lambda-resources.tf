###############################
# Lambda@Edge – ONLY for HTTP distribution
###############################

# -------------------------------------------------
# 1. IAM Role
# -------------------------------------------------
resource "aws_iam_role" "lambda_edge_role" {
  name     = "CloudfrontRedirectLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
        }
      }
    ]
  })

  tags = {
    Name        = "lambda_edge_role"
    Environment = local.environment
  }
}

# -------------------------------------------------
# 2. IAM Policy – ONLY CloudWatch Logs
# -------------------------------------------------
resource "aws_iam_role_policy" "lambda_edge_policy" {
  name     = "CloudfrontRedirectLambdaPolicy"
  role     = aws_iam_role.lambda_edge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:PublishVersion",
          "lambda:GetFunction",
          "lambda:UpdateFunctionConfiguration",
          "lambda:AddPermission",
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:us-east-1:${data.aws_caller_identity.current.account_id}:function:CloudfrontRedirectLambda"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/CloudfrontRedirectLambda:*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = aws_iam_role.lambda_edge_role.arn
        Condition = {
          StringEquals = {
            "iam:PassedToService" = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
          }
        }
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
  provider         = aws.us-east-1
  function_name    = "CloudfrontRedirectLambda"
  filename         = local.is-production ? data.archive_file.lambda_zip.output_path : data.archive_file.lambda_zip_nonprod.output_path
  source_code_hash = sha256(
      "${local.is_production ? data.archive_file.lambda_zip.output_base64sha256 : data.archive_file.lambda_zip_nonprod.output_base64sha256}" +
      null_resource.force_replication.triggers.cloudfront_arn
    )
  role             = aws_iam_role.lambda_edge_role.arn
  handler          = "cloudfront-redirect.handler"
  runtime          = "nodejs18.x"
  publish          = true
  timeout          = 5
  memory_size      = 128

  tags = {
   Name        = "cloudfront_redirect_lambda"
   Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [null_resource.force_replication]
  }

}

# This dummy file forces a new version when CloudFront ARN changes
resource "null_resource" "force_replication" {
  triggers = {
    cloudfront_arn = aws_cloudfront_distribution.tribunals_http_redirect.arn
    lambda_version = aws_lambda_function.cloudfront_redirect_lambda.version
  }
}

# -------------------------------------------------
# 5. Allow ONLY the HTTP distribution to invoke
# -------------------------------------------------
resource "aws_lambda_permission" "allow_http_cloudfront" {
  provider      = aws.us-east-1
  statement_id  = "AllowHttpCloudFrontExecution"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudfront_redirect_lambda.function_name
  principal     = "edgelambda.amazonaws.com"
  source_arn    = aws_cloudfront_distribution.tribunals_http_redirect.arn
}