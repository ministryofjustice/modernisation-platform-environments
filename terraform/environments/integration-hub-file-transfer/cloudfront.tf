module "cloudfront_web_app" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "6.7.1"

  aliases               = [aws_acm_certificate.web_app.domain_name]
  comment               = "Integration Hub File Transfer web app"
  enabled               = true
  http_version          = "http2"
  is_ipv6_enabled       = true
  origin_access_control = {}
  price_class           = "PriceClass_100"
  web_acl_id            = module.waf_web_app.web_acl_arn
  wait_for_deployment   = true

  origin = {
    transfer-web-app = {
      domain_name = "${aws_transfer_web_app.this.web_app_id}.transfer-webapp.${data.aws_region.current.region}.on.aws"

      custom_header = {
        X-Transfer-WebApp-Custom-Domain-Template-Version = "2024-12-01"
      }

      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior = {
    allowed_methods              = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods               = ["GET", "HEAD"]
    target_origin_id             = "transfer-web-app"
    viewer_protocol_policy       = "https-only"
    cache_policy_name            = "Managed-CachingDisabled"
    origin_request_policy_name   = "Managed-AllViewerExceptHostHeader"
    response_headers_policy_name = "Managed-SecurityHeadersPolicy"
  }

  viewer_certificate = {
    acm_certificate_arn      = aws_acm_certificate_validation.web_app.certificate_arn
    minimum_protocol_version = "TLSv1.2_2025"
    ssl_support_method       = "sni-only"
  }

  enable_v2_logging = true
  v2_logging = {
    name          = "${local.application_name}-${local.environment}-web-access"
    output_format = "json"
    delivery_destination_configuration = {
      destination_resource_arn = module.cloudwatch_web_app["cloudfront"].cloudwatch_log_group_arn
    }
    record_fields = [
      "date",
      "time",
      "x-edge-location",
      "c-ip",
      "cs-method",
      "cs(Host)",
      "cs-uri-stem",
      "sc-status",
      "sc-bytes",
      "cs-bytes",
      "time-taken",
      "x-edge-result-type",
      "x-edge-request-id",
      "x-edge-detailed-result-type",
      "ssl-protocol",
      "ssl-cipher",
    ]
  }

  tags = local.tags
}