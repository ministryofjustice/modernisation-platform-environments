resource "aws_cloudfront_distribution" "nginx_distribution" {
  count = local.is-production ? 0 : 1

  aliases = [
    "tribunals.gov.uk",
    "*.tribunals.gov.uk",
    "*.decisions.tribunals.gov.uk",
    "administrativeappeals.tribunals.gov.uk",
    "ahmlr.gov.uk",
    "asylum-support-tribunal.gov.uk",
    "carestandardstribunal.gov.uk",
    "charity.tribunals.gov.uk",
    "courtfunds.gov.uk",
    "www.courtfunds.gov.uk",
    "criminal-courts-review.org.uk",
    "www.criminal-courts-review.org.uk",
    "courts.gov.uk",
    "www.courts.gov.uk",
    "dca.gov.uk",
    "www.dca.gov.uk",
    "familyjusticecouncil.org.uk",
    "www.familyjusticecouncil.org.uk",
    "hmica.gov.uk",
    "www.hmica.gov.uk",
    "hmctsformfinder.justice.gov.uk",
    "informationtribunal.gov.uk",
    "informationtribunal.dsd.io",
    "judicialappointments.gov.uk",
    "landstribunal.gov.uk",
    "lscc.org.uk",
    "www.lscc.org.uk",
    "lsconlinesso.legalservices.gov.uk",
    "magistrates.org.uk",
    "www.magistrates.org.uk",
    "pensionsappealtribunals.gov.uk",
    "www.pensionsappealtribunals.gov.uk",
    "publicguardian.gov.uk",
    "www.publicguardian.gov.uk",
    "tribunals-review.org.uk",
    "www.tribunals-review.org.uk",
    "walesoffice.gov.uk",
    "www.walesoffice.gov.uk",
    "xhibit.gov.uk",
    "www.xhibit.gov.uk",
    "yjbpublications.justice.gov.uk",
    "www.yjbpublications.justice.gov.uk"
  ]
  
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Nginx redirects distribution"
  price_class         = "PriceClass_All"
  wait_for_deployment = false

  origin {
    domain_name = module.nginx_load_balancer[0].nginx_lb_dns_name
    origin_id   = "ALB"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_keepalive_timeout = 60
      origin_read_timeout     = 60
    }
  }

  default_cache_behavior {
    target_origin_id = "ALB"

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    smooth_streaming       = false
  }

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

resource "aws_acm_certificate" "cloudfront_nginx" {
  count = local.is-production ? 0 : 1

  provider          = aws.us-east-1
  domain_name       = "tribunals.gov.uk"
  validation_method = "DNS"
  
  subject_alternative_names = [
    "*.tribunals.gov.uk",
    "administrativeappeals.tribunals.gov.uk",
    "ahmlr.gov.uk",
    "asylum-support-tribunal.gov.uk",
    "carestandardstribunal.gov.uk",
    "charity.tribunals.gov.uk",
    "courtfunds.gov.uk",
    "www.courtfunds.gov.uk",
    "criminal-courts-review.org.uk",
    "www.criminal-courts-review.org.uk",
    "courts.gov.uk",
    "www.courts.gov.uk",
    "dca.gov.uk",
    "www.dca.gov.uk",
    "familyjusticecouncil.org.uk",
    "www.familyjusticecouncil.org.uk",
    "hmica.gov.uk",
    "www.hmica.gov.uk",
    "hmctsformfinder.justice.gov.uk",
    "informationtribunal.gov.uk",
    "informationtribunal.dsd.io",
    "judicialappointments.gov.uk",
    "landstribunal.gov.uk",
    "lscc.org.uk",
    "www.lscc.org.uk",
    "lsconlinesso.legalservices.gov.uk",
    "magistrates.org.uk",
    "www.magistrates.org.uk",
    "pensionsappealtribunals.gov.uk",
    "www.pensionsappealtribunals.gov.uk",
    "publicguardian.gov.uk",
    "www.publicguardian.gov.uk",
    "tribunals-review.org.uk",
    "www.tribunals-review.org.uk",
    "walesoffice.gov.uk",
    "www.walesoffice.gov.uk",
    "xhibit.gov.uk",
    "www.xhibit.gov.uk",
    "yjbpublications.justice.gov.uk",
    "www.yjbpublications.justice.gov.uk"
  ]

  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "nginx_cloudfront_cert_validation" {
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.cloudfront.arn
}