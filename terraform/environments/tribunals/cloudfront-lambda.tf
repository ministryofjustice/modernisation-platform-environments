###############################
#  SECOND CLOUDFRONT – HTTP-only to replace nginx server in old DSD AWS account
#  DNS records managed by
###############################

# Lambda@Edge + ACM must be in us-east-1
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# -------------------------------------------------
# 1. ACM Certificate (HTTP-only domains only)
# -------------------------------------------------
resource "aws_acm_certificate" "http_redirect_cert" {
  provider          = aws.us-east-1
  domain_name       = "siac.tribunals.gov.uk"  # any one of your HTTP domains
  validation_method = "DNS"

  subject_alternative_names = [
    "siac.tribunals.gov.uk",
    "fhsaa.tribunals.gov.uk",
    "estateagentappeals.tribunals.gov.uk",
    "consumercreditappeals.tribunals.gov.uk",
    "charity.tribunals.gov.uk",
    "adjudicationpanel.tribunals.gov.uk",
    "asylum-support-tribunal.gov.uk",
    "ahmlr.gov.uk",
    "appeals-service.gov.uk",
    "carestandardstribunal.gov.uk",
    "cicap.gov.uk",
    "civilappeals.gov.uk",
    "cjit.gov.uk",
    "cjs.gov.uk",
    "cjsonline.gov.uk",
    "complaints.judicialconduct.gov.uk",
    "courtfines.justice.gov.uk",
    "courtfunds.gov.uk",
    "criminal-justice-system.gov.uk",
    "dugganinquest.independent.gov.uk",
    "employmentappeals.gov.uk",
    "financeandtaxtribunals.gov.uk",
    "hillsboroughinquests.independent.gov.uk",
    "immigrationservicestribunal.gov.uk",
    "informationtribunal.gov.uk",
    "judicialombudsman.gov.uk",
    "landstribunal.gov.uk",
    "obr.co.uk",
    "osscsc.gov.uk",
    "paroleboard.gov.uk",
    "sendmoneytoaprisoner.justice.gov.uk",
    "transporttribunal.gov.uk",
    "victiminformationservice.org.uk",
    "yjbpublications.justice.gov.uk"
  ]

  tags = {
    Name        = "tribunals-http-redirect-cert"
    Environment = "production"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -------------------------------------------------
# 2. OUTPUT: DNS Validation Records
# -------------------------------------------------
output "cert_validation_records" {
  description = <<EOF
Give these to the external AWS account admins.
They must create **CNAME** records in their Route 53 zone.
EOF

  value = [
    for dvo in aws_acm_certificate.http_redirect_cert.domain_validation_options : {
      domain = dvo.domain_name
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
    }
  ]
}

# -------------------------------------------------
# 3. CloudFront Distribution – HTTP only
# -------------------------------------------------
resource "aws_cloudfront_distribution" "tribunals_http_redirect" {
  provider = aws.us-east-1

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "HTTP-only → HTTPS redirect (external DNS)"
  price_class         = "PriceClass_All"
  http_version        = "http2"

  # Reuse the same domain list as aliases
  aliases = aws_acm_certificate.http_redirect_cert.subject_alternative_names

  # Use the **new dedicated certificate**
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.http_redirect_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Dummy origin (never hit)
  origin {
    domain_name = "dummy-http-redirect.s3.amazonaws.com"
    origin_id   = "dummy-http-origin"

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  default_cache_behavior {
    target_origin_id       = "dummy-http-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    # Reuse existing Lambda@Edge
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.tribunals_redirect_lambda.qualified_arn
      include_body = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = "tribunals-http-redirect"
    Environment = "production"
  }

  # Wait for cert to be issued before creating distribution
  depends_on = [
    aws_acm_certificate.http_redirect_cert,
    aws_lambda_function.tribunals_redirect_lambda,
    aws_lambda_permission.allow_cloudfront
  ]
}

# -------------------------------------------------
# 4. OUTPUT: CloudFront Domain Name (for final CNAME)
# -------------------------------------------------
output "http_redirect_distribution_domain" {
  description = "CNAME target for HTTP domains (give to external DNS admins)"
  value       = aws_cloudfront_distribution.tribunals_http_redirect.domain_name
}

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