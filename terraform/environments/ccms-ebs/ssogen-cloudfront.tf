# resource "aws_route53_record" "ssogen_cloudfront" {
#   count    = (local.is-development || local.is-test) ? 1 : 0
#   provider = aws.core-vpc
#   zone_id  = data.aws_route53_zone.external.zone_id
#   name     = "ccmsebs-sso-cf"
#   type     = "CNAME"
#   ttl      = 300
#   records  = [aws_cloudfront_distribution.transfer_family[0].domain_name]
# }

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
# resource "aws_wafv2_ip_set" "transfer_family" {
#   count              = (local.is-preproduction || local.is-production) ? 1 : 0
#   provider           = aws.us-east-1
#   name               = "laa-allow-list"
#   description        = "Allowed Internal Ranges for LAA"
#   scope              = "CLOUDFRONT"
#   ip_address_version = "IPV4"
#   addresses = [
#     "51.149.249.0/29",
#     "194.33.249.0/29",
#     "51.149.249.32/29",
#     "194.33.248.0/29",
#     "20.49.214.199/32",
#     "20.49.214.228/32",
#     "20.26.11.71/32",
#     "20.26.11.108/32",
#     "128.77.75.64/26",
#     "18.169.147.172/32",
#     "35.176.93.186/32",
#     "18.130.148.126/32",
#     "35.176.148.126/32",
#     "35.176.127.232/32", # London Non-Prod NAT Gateway
#     "35.177.145.193/32", # London Non-Prod NAT Gateway
#     "18.130.39.94/32",   # London Non-Prod NAT Gateway
#     "52.56.212.11/32",   # London Prod NAT Gateway
#     "35.176.254.38/32",  # London Prod NAT Gateway
#     "35.177.173.197/32"  # London Prod NAT Gateway
#   ]
# }

# resource "aws_wafv2_web_acl" "transfer_family" {
#   count       = (local.is-preproduction || local.is-production) ? 1 : 0
#   provider    = aws.us-east-1
#   name        = "cf-ip-restriction-acl"
#   description = "LAA Cash Office Allowed"
#   scope       = "CLOUDFRONT"
#   default_action {
#     block {}
#   }
#   rule {
#     name     = "allow-specific-ips"
#     priority = 0
#     action {
#       allow {}
#     }
#     statement {
#       ip_set_reference_statement {
#         arn = aws_wafv2_ip_set.transfer_family[0].arn
#       }
#     }
#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AllowSpecificIPs"
#       sampled_requests_enabled   = true
#     }
#   }
#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name                = "CloudFrontIPACL"
#     sampled_requests_enabled   = true
#   }
# }

# resource "aws_cloudfront_distribution" "transfer_family" {
#   count           = (local.is-preproduction || local.is-production) ? 1 : 0
#   enabled         = true
#   comment         = "CloudFront Distribution: cashoffice"
#   is_ipv6_enabled = false
#   http_version    = "http2" # Automatically supports http/2, http/1.1, and http/1.0
#   aliases         = ["${local.application_data.accounts[local.environment].cash_office_upload_hostname}.${trim(data.aws_route53_zone.external.name, ".")}"]
#   origin {
#     domain_name = local.application_data.accounts[local.environment].cash_web_app_url
#     origin_id   = "transfer-family"

#     custom_origin_config {
#       http_port              = 80
#       https_port             = 443
#       origin_protocol_policy = "https-only"
#       origin_ssl_protocols   = ["TLSv1.2"]
#     }
#     custom_header {
#       name  = "X-Transfer-WebApp-Custom-Domain-Template-Version"
#       value = "2024-12-01"
#     }
#   }
#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }
#   default_cache_behavior {
#     cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Caching Disabled
#     origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader
#     target_origin_id         = "transfer-family"
#     viewer_protocol_policy   = "redirect-to-https"
#     allowed_methods          = ["GET", "HEAD"]
#     cached_methods           = ["GET", "HEAD"]
#     compress                 = true
#   }
#   viewer_certificate {
#     cloudfront_default_certificate = false
#     acm_certificate_arn            = aws_acm_certificate_validation.transfer_family[0].certificate_arn
#     ssl_support_method             = "sni-only"
#   }
#   web_acl_id = aws_wafv2_web_acl.transfer_family[0].arn
# }
