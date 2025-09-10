resource "aws_cloudfront_distribution" "tribunals_distribution_nginx" {
  #checkov:skip=CKV_AWS_86:"Access logging not required for this distribution"
  #checkov:skip=CKV_AWS_374:"Geo restriction not needed for this public service"
  #checkov:skip=CKV_AWS_305:"Default root object not required as this is an API distribution"
  #checkov:skip=CKV_AWS_310:"Single origin is sufficient for this use case"
  #checkov:skip=CKV2_AWS_47:"Skip Log4j protection as it is handled via WAF"
  #checkov:skip=CKV2_AWS_46:"Origin Access Identity not applicable as origin is ALB, not S3"

  count = local.is-development ? 0 : 1

  web_acl_id = aws_wafv2_web_acl.tribunals_web_acl.arn

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "cloudfront-logs/"
  }

  aliases = local.is-development ? [
    "*.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  ] : [
    "siac.tribunals.gov.uk"
  ]
  

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
    default_ttl            = 0
    min_ttl                = 0
    max_ttl                = 31536000
    smooth_streaming       = false

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect_function[0].arn
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront distribution for tribunals nginx load balancer"
  price_class     = "PriceClass_All"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront_nginx[0].arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

// Create a new certificate for the CloudFront distribution because it needs to be in us-east-1
resource "aws_acm_certificate" "cloudfront_nginx" {
  count = local.is-development ? 0 : 1
  provider                  = aws.us-east-1
  domain_name               = local.is-development ? "modernisation-platform.service.justice.gov.uk": "siac.tribunals.gov.uk"
  validation_method         = "DNS"
  subject_alternative_names = local.is-development ? ["*.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"] : ["siac.tribunals.gov.uk"]

  tags = {
    Environment = local.environment
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cloudfront_cert_validation_nginx" {
  count = local.is-development ? 0 : 1
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.cloudfront_nginx[0].arn
}

resource "aws_cloudfront_function" "redirect_function" {
  count = local.is-development ? 0 : 1
  name    = "tribunals_redirect_function"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<EOF
  function handler(event) {
    var request = event.request;
    var host    = request.headers.host.value;
    var uri     = request.uri;

    // Redirect rules for siac.tribunals.gov.uk
    if (host === "siac.tribunals.gov.uk") {
      if (uri.toLowerCase() === "/outcomes2007onwards.htm") {
        return {
          statusCode: 301,
          statusDescription: "Moved Permanently",
          headers: {
            "location": { "value": "https://siac.decisions.tribunals.gov.uk" }
          }
        };
      }
      return {
        statusCode: 301,
        statusDescription: "Moved Permanently",
        headers: {
          "location": { "value": "https://www.gov.uk/guidance/appeal-to-the-special-immigration-appeals-commission" }
        }
      };
    }

    // Default: Pass through to origin
    return request;
  }
  EOF
}


