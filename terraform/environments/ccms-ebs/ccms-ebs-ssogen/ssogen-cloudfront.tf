resource "aws_route53_record" "ssogen_cloudfront" {
  count    = (local.is-development || local.is-test) ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ccmsebs-sso-cf"
  type     = "CNAME"
  ttl      = 300
  records  = [aws_cloudfront_distribution.ssogen_cloudfront_distribution[count.index].domain_name]
}

# #--Certs need to be created in us-east-1 as they are associated with Cloudfront
# resource "aws_acm_certificate" "ssogen_cloudfront_cert" {
#   count    = (local.is-development || local.is-test) ? 1 : 0
#   provider                  = aws.us-east-1
#   domain_name               = trim(data.aws_route53_zone.external.name, ".") #--Remove the trailing dot from the zone name
#   subject_alternative_names = ["${local.application_data.accounts[local.environment].cash_office_upload_hostname}.${trim(data.aws_route53_zone.external.name, ".")}"]
#   validation_method         = "DNS"
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_acm_certificate_validation" "ssogen_cloudfront_cert_validation" {
#   count    = (local.is-development || local.is-test) ? 1 : 0
#   provider                = aws.us-east-1
#   certificate_arn         = aws_acm_certificate.ssogen_cloudfront_cert[count.index].arn
#   validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
# }

# #--See member_locals.tf for the validation logic underpinning this resource
# resource "aws_route53_record" "validation" {
#   provider        = aws.core-vpc
#   for_each        = local.transfer_family_dvo_map
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.external.zone_id
# }

# #--WAF and ACL resources need to be in us-east-1 as they are associated with Cloudfront
resource "aws_wafv2_ip_set" "ssogen_cloudfront_ips" {
  count       = (local.is-development || local.is-test) ? 1 : 0
  provider           = aws.us-east-1
  name               = "laa-ssogen-allow-list"
  description        = "Allowed Internal Ranges for LAA"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses = [
    "51.149.249.0/29",
    "194.33.249.0/29",
    "51.149.249.32/29",
    "194.33.248.0/29",
    "20.49.214.199/32",
    "20.49.214.228/32",
    "20.26.11.71/32",
    "20.26.11.108/32",
    "128.77.75.64/26",
    "18.169.147.172/32",
    "35.176.93.186/32",
    "18.130.148.126/32",
    "35.176.148.126/32",
    "35.176.127.232/32", # London Non-Prod NAT Gateway
    "35.177.145.193/32", # London Non-Prod NAT Gateway
    "18.130.39.94/32",   # London Non-Prod NAT Gateway
    "52.56.212.11/32",   # London Prod NAT Gateway
    "35.176.254.38/32",  # London Prod NAT Gateway
    "35.177.173.197/32"  # London Prod NAT Gateway
  ]
}

resource "aws_wafv2_web_acl" "ssogen_cloudfront_acl" {
  count       = (local.is-development || local.is-test) ? 1 : 0
  provider    = aws.us-east-1
  name        = "cf-ssogen-ip-restriction-acl"
  description = "LAA Case Worker SSOGen CloudFront ACL - allows traffic only from specific IP ranges"
  scope       = "CLOUDFRONT"
  default_action {
    block {}
  }
  rule {
    name     = "allow-specific-ips"
    priority = 0
    action {
      allow {}
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ssogen_cloudfront_ips[0].arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowSpecificIPs"
      sampled_requests_enabled   = true
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "CloudFrontIPACL"
    sampled_requests_enabled   = true
  }
}

data "aws_s3_bucket" "logs" {
  bucket = "${local.application_name}-${local.environment}-logging"
}

resource "aws_cloudfront_distribution" "ssogen_cloudfront_distribution" {
  count           = (local.is-development || local.is-test) ? 1 : 0
  enabled         = true
  comment         = "CloudFront Distribution: ssogen-cloudfront-${local.environment}"
  is_ipv6_enabled = false
  http_version    = "http2" # Automatically supports http/2, http/1.1, and http/1.0
  aliases         = [format("ccmsebs-sso-cf.%s-%s.modernisation-platform.service.justice.gov.uk", var.networking[0].business-unit, local.environment)]
  logging_config {
    include_cookies = false
    bucket          = data.aws_s3_bucket.logs.id
    prefix          = "ssogen-cloudfront/"
  }

  origin {
    domain_name = format("ccmsebs-sso.%s-%s.modernisation-platform.service.justice.gov.uk", var.networking[0].business-unit, local.environment)
    origin_id   = "ssogen-load-balancer-internal"

    custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
    }

  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_100"
  default_cache_behavior {
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Caching Disabled
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader
    target_origin_id         = "ssogen-load-balancer-internal"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["GET", "HEAD","POST", "OPTIONS", "PUT","PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
  }
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate_validation.external_nonprod[0].certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
  web_acl_id = aws_wafv2_web_acl.ssogen_cloudfront_acl[0].arn
  tags       = merge(local.tags,
    { Name = format("%s-%s", local.application_name_ssogen, local.environment) }
  )
}

resource "aws_wafv2_web_acl_association" "ssogen_cloudfront_acl_association" {
  count      = (local.is-development || local.is-test) ? 1 : 0
  provider   = aws.us-east-1
  resource_arn = aws_cloudfront_distribution.ssogen_cloudfront_distribution[0].arn
  web_acl_arn  = aws_wafv2_web_acl.ssogen_cloudfront_acl[0].arn

}
