resource "aws_cloudfront_distribution" "tribunals_distribution" {
  #checkov:skip=CKV_AWS_86:"Access logging not required for this distribution"
  #checkov:skip=CKV_AWS_374:"Geo restriction not needed for this public service"
  #checkov:skip=CKV_AWS_305:"Default root object not required as this is an API distribution"
  #checkov:skip=CKV_AWS_310:"Single origin is sufficient for this use case"

  web_acl_id = aws_wafv2_web_acl.tribunals_web_acl.arn

  logging_config {
    include_cookies = false
    bucket         = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix         = "cloudfront-logs/"
  }

  aliases = local.is-production ? [
    "*.decisions.tribunals.gov.uk",
    "*.venues.tribunals.gov.uk",
    "*.reports.tribunals.gov.uk"
  ] : ["*.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
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

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    default_ttl            = 0
    min_ttl                = 0
    max_ttl                = 31536000
    smooth_streaming       = false
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront distribution for tribunals load balancer"
  price_class     = "PriceClass_All"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
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
  subject_alternative_names = local.is-production ? ["*.venues.tribunals.gov.uk", "*.reports.tribunals.gov.uk"] : ["*.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
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
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "tribunals_lb_sg_cloudfront" {
  #checkov:skip=CKV_AWS_382:"Load balancer requires unrestricted egress for dynamic port mapping"
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
  bucket = "tribunals-cloudfront-logs-${local.environment}"
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
      sse_algorithm = "AES256"
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
        Resource = "${aws_s3_bucket.cloudfront_logs.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          StringLike = {
            "aws:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.tribunals_distribution.id}"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}
