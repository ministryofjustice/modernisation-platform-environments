# locals {
#     custom_header = "X-Custom-Header-LAA-${upper(var.application_name)}"
#     cloudfront_alias = local.environment == "production" ? ${local.application_data.accounts[local.environment].domain_name} : "meansassessment.${var.networking[0].business-unit}-${local.environment}.${local.application_data.accounts[local.environment].domain_name}"
# }

# # data "aws_ec2_managed_prefix_list" "cloudfront" {
# #   name = "com.amazonaws.global.cloudfront.origin-facing"
# # }

# resource "random_password" "cloudfront" {
#   length  = 16
#   special = false
# }

# resource "aws_secretsmanager_secret" "cloudfront" {
#   name        = "cloudfront-secret-${var.application_name}" # ${formatdate("DDMMMYYYYhhmm", timestamp())}
#   description = "Simple secret created by AWS CloudFormation to be shared between ALB and CloudFront"
# }

# resource "aws_secretsmanager_secret_version" "cloudfront" {
#   secret_id     = aws_secretsmanager_secret.cloudfront.id
#   secret_string = random_password.cloudfront.result
# }

# # Importing the AWS secrets created previously using arn.
# data "aws_secretsmanager_secret" "cloudfront" {
#   arn = aws_secretsmanager_secret.cloudfront.arn
# }

# # Importing the AWS secret version created previously using arn.
# data "aws_secretsmanager_secret_version" "cloudfront" {
#   secret_id = data.aws_secretsmanager_secret.cloudfront.arn
# }

# # resource "aws_s3_bucket" "cloudfront" { # Mirroring laa-cloudfront-logging-development in laa-dev
# #   bucket = "laa-${var.application_name}-cloudfront-logging-${var.environment}"
# #   # force_destroy = true # Enable to recreate bucket deleting everything inside
# #   tags = merge(
# #     var.tags,
# #     {
# #       Name = "laa-${var.application_name}-cloudfront-logging-${var.environment}"
# #     }
# #   )
# #   # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
# #   lifecycle {
# #     prevent_destroy = false
# #   }
# # }

# # resource "aws_s3_bucket_ownership_controls" "cloudfront" {
# #   bucket = aws_s3_bucket.cloudfront.id
# #   rule {
# #     object_ownership = "BucketOwnerPreferred"
# #   }
# # }

# # resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront" {
# #   bucket = aws_s3_bucket.cloudfront.id
# #   rule {
# #     apply_server_side_encryption_by_default {
# #       sse_algorithm = "AES256"
# #     }
# #   }
# #   # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
# #   lifecycle {
# #     prevent_destroy = false
# #   }
# # }

# # resource "aws_s3_bucket_public_access_block" "cloudfront" {
# #   bucket = aws_s3_bucket.cloudfront.id

# #   block_public_acls       = true
# #   block_public_policy     = true
# #   ignore_public_acls      = true
# #   restrict_public_buckets = true
# #   # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
# #   lifecycle {
# #     prevent_destroy = false
# #   }
# # }

# resource "aws_cloudfront_distribution" "external" {
#   http_version = "http2"
#   origin {
#     domain_name = aws_lb.loadbalancer.dns_name # TODO update with the actual LB
#     origin_id   = aws_lb.loadbalancer.id # TODO update with the actual LB
#     custom_origin_config {
#       http_port                = 80 # This port was not defined in CloudFormation, but should not be used anyways, only required by Terraform
#       https_port               = 443
#       origin_protocol_policy   = "https-only"
#       origin_ssl_protocols     = ["TLSv1.2"]
#       origin_read_timeout      = 60
#       origin_keepalive_timeout = 60
#     }
#     custom_header {
#       name  = local.custom_header
#       value = data.aws_secretsmanager_secret_version.cloudfront.secret_string
#     }
#   }
#   enabled = "true"
#   aliases = [local.cloudfront_alias]
#   default_cache_behavior {
#     target_origin_id = aws_lb.loadbalancer.id
#     smooth_streaming = lookup(var.cloudfront_default_cache_behavior, "smooth_streaming", null)
#     allowed_methods  = lookup(var.cloudfront_default_cache_behavior, "allowed_methods", null)
#     cached_methods   = lookup(var.cloudfront_default_cache_behavior, "cached_methods", null)
#     forwarded_values {
#       query_string = lookup(var.cloudfront_default_cache_behavior, "forwarded_values_query_string", null)
#       headers      = lookup(var.cloudfront_default_cache_behavior, "forwarded_values_headers", null)
#       cookies {
#         forward           = lookup(var.cloudfront_default_cache_behavior, "forwarded_values_cookies_forward", null)
#         whitelisted_names = lookup(var.cloudfront_default_cache_behavior, "forwarded_values_cookies_whitelisted_names", null)
#       }
#     }
#     viewer_protocol_policy = lookup(var.cloudfront_default_cache_behavior, "viewer_protocol_policy", null)
#   }

#   dynamic "ordered_cache_behavior" {
#     for_each = var.cloudfront_ordered_cache_behavior
#     content {
#       target_origin_id = aws_lb.loadbalancer.id
#       smooth_streaming = lookup(ordered_cache_behavior.value, "smooth_streaming", null)
#       path_pattern     = lookup(ordered_cache_behavior.value, "path_pattern", null)
#       min_ttl          = lookup(ordered_cache_behavior.value, "min_ttl", null)
#       default_ttl      = lookup(ordered_cache_behavior.value, "default_ttl", null)
#       max_ttl          = lookup(ordered_cache_behavior.value, "max_ttl", null)
#       allowed_methods  = lookup(ordered_cache_behavior.value, "allowed_methods", null)
#       cached_methods   = lookup(ordered_cache_behavior.value, "cached_methods", null)
#       forwarded_values {
#         query_string = lookup(ordered_cache_behavior.value, "forwarded_values_query_string", null)
#         headers      = lookup(ordered_cache_behavior.value, "forwarded_values_headers", null)
#         cookies {
#           forward           = lookup(ordered_cache_behavior.value, "forwarded_values_cookies_forward", null)
#           whitelisted_names = lookup(ordered_cache_behavior, "forwarded_values_cookies_whitelisted_names", null)
#         }
#       }
#       viewer_protocol_policy = lookup(ordered_cache_behavior.value, "viewer_protocol_policy", null)
#     }
#   }

#   price_class = var.cloudfront_price_class

#   viewer_certificate {
#     acm_certificate_arn      = aws_acm_certificate.cloudfront.arn
#     ssl_support_method       = "sni-only"
#     minimum_protocol_version = "TLSv1.2_2018"
#   }

#   logging_config {
#     include_cookies = false
#     bucket          = aws_s3_bucket.cloudfront.bucket_domain_name
#     prefix          = var.application_name
#   }
#   web_acl_id = aws_waf_web_acl.waf_acl.id

#   restrictions {
#     geo_restriction {
#       restriction_type = var.cloudfront_geo_restriction_type
#       locations        = var.cloudfront_geo_restriction_location
#     }
#   }

#   is_ipv6_enabled = var.cloudfront_is_ipv6_enabled

#   tags = var.tags

# }