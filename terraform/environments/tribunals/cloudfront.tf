resource "aws_cloudfront_distribution" "tribunals_distribution" {
  #checkov:skip=CKV_AWS_86:"Access logging not required for this distribution"
  #checkov:skip=CKV_AWS_374:"Geo restriction not needed for this public service"
  #checkov:skip=CKV_AWS_305:"Default root object not required as this is an API distribution"
  #checkov:skip=CKV_AWS_310:"Single origin is sufficient for this use case"
  #checkov:skip=CKV2_AWS_47:"Skip Log4j protection as it is handled via WAF"
  #checkov:skip=CKV2_AWS_46:"Origin Access Identity not applicable as origin is ALB, not S3"

  web_acl_id = aws_wafv2_web_acl.tribunals_web_acl.arn

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "cloudfront-logs-v2/"
  }

  aliases = local.is-production ? concat(local.common_sans, local.cloudfront_sans, ["*.decisions.tribunals.gov.uk"]) : local.nonprod_sans
  origin {
    domain_name = aws_lb.tribunals_lb.dns_name
    origin_id   = "tribunalsOrigin"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 60
      origin_read_timeout      = 60
    }

    custom_header {
      name  = "X-Custom-Header"
      value = "tribunals-origin"
    }
  }

  default_cache_behavior {
    target_origin_id = "tribunalsOrigin"

    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers_policy.id

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    smooth_streaming       = false

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.cloudfront_redirect_lambda.qualified_arn
      include_body = false
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront distribution for tribunals load balancer"
  price_class     = "PriceClass_All"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront_cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  depends_on = [
    aws_lambda_function.cloudfront_redirect_lambda
  ]
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

// Create a new certificate for the CloudFront distribution because it needs to be in us-east-1
resource "aws_acm_certificate" "cloudfront" {
  provider                  = aws.us-east-1
  domain_name               = local.is-production ? "*.decisions.tribunals.gov.uk" : "modernisation-platform.service.justice.gov.uk"
  validation_method         = "DNS"
  subject_alternative_names = local.is-production ? concat(local.common_sans, local.cloudfront_sans) : local.nonprod_sans

  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cloudfront_cert_validation" {
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [
    for record in aws_route53_record.cloudfront_cert_cname_validation : record.fqdn
  ]
}

// Route53 DNS records for certificate validation
// Don't duplicate the common_sans domains here - already generated in dns_ssl.tf
resource "aws_route53_record" "cloudfront_cert_cname_validation" {
  provider = aws.core-network-services

  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.value]
  ttl             = 300
  type            = each.value.type
  zone_id         = local.is-production ? data.aws_route53_zone.production_zone.zone_id : data.aws_route53_zone.network-services.zone_id
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "tribunals_lb_sg_cloudfront" {
  #checkov:skip=CKV_AWS_382:"Load balancer requires unrestricted egress for dynamic port mapping"
  #checkov:skip=CKV2_AWS_5:"Security group is attached to the tribunals load balancer"
  name        = "tribunals-load-balancer-sg-cf"
  description = "control access to the load balancer using cloudfront"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description     = "Allow CloudFront traffic on HTTPS port 443"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    description = "allow all outbound traffic from the load balancer - needed due to dynamic port mapping on ec2 instance"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "cloudfront_logs" {
  #checkov:skip=CKV2_AWS_62:"Event notifications not required for CloudFront logs bucket"
  #checkov:skip=CKV_AWS_144:"Cross-region replication not required"
  #checkov:skip=CKV_AWS_18:"Access logging not required for CloudFront logs bucket to avoid logging loop"
  bucket = "tribunals-cloudfront-logs-${local.environment}"
}

resource "aws_s3_bucket_versioning" "cloudfront_bucket_versioning" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  #checkov:skip=CKV2_AWS_65:"ACLs are required for CloudFront logging to work"
  bucket = aws_s3_bucket.cloudfront_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs]
  bucket     = aws_s3_bucket.cloudfront_logs.id
  acl        = "log-delivery-write"
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontLogDelivery"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudfront_logs.arn}/cloudfront-logs-v2/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            "aws:SourceArn"     = aws_cloudfront_distribution.tribunals_distribution.arn
          }
        }
      },
      {
        Sid    = "AllowCloudFrontLogDeliveryGetBucketAcl"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudfront_logs.arn
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    filter {
      prefix = "cloudfront-logs/"
    }

    expiration {
      days = 90
    }
  }

  rule {
    id     = "abort-multipart"
    status = "Enabled"

    filter {
      prefix = "" //Empty prefix means apply to all objects
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "security_headers_policy" {
  name    = "tribunals-security-headers-policy"
  comment = "Security headers policy for tribunals CloudFront distribution"

  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'"
      override                = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }
}

# IAM Policy for Lambda@Edge
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

# Lambda Permission for CloudFront
resource "aws_lambda_permission" "allow_cloudfront" {
  provider      = aws.us-east-1
  statement_id  = "AllowCloudFrontExecution"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudfront_redirect_lambda.function_name
  principal     = "edgelambda.amazonaws.com"
  source_arn    = aws_cloudfront_distribution.tribunals_distribution.arn
}
