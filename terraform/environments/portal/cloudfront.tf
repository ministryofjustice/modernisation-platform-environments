#locals {
# custom_header   = "X-Custom-Header-LAA-${upper(var.application_name)}"
#custom_header     = "X-Custom-Header-LAA-${upper(local.application_name)}"
# fqdn            == "production" ? local.application_data.accounts[local.environment].hosted_zone : "${local.application_name}.${var.networking[0].business-unit}-${local.environment}.${local.application_data.accounts[local.environment].hosted_zone}"

# data "aws_ec2_managed_prefix_list" "cloudfront" {
#   name = "com.amazonaws.global.cloudfront.origin-facing"
# }
#}

locals {
cloudfront_validation_records = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
      zone = lookup(
        local.route53_zones,
        dvo.domain_name,
        lookup(
          local.route53_zones,
          replace(dvo.domain_name, "/^[^.]*./", ""),
          lookup(
            local.route53_zones,
            replace(dvo.domain_name, "/^[^.]*.[^.]*./", ""),
            { provider = "external" }
      )))
    }
  }

  # core_network_services_domains = {
  #   for domain, value in var.validation : domain => value if value.account == "core-network-services"
  # }
  # core_vpc_domains = {
  #   for domain, value in var.validation : domain => value if value.account == "core-vpc"
  # }
  # self_domains = {
  #   for domain, value in var.validation : domain => value if value.account == "self"
  # }

#   route53_zones = merge({
#     for key, value in data.aws_route53_zone.core_network_services : key => merge(value, {
#       provider = "core-network-services"
#     })
#     }, {
#     for key, value in data.aws_route53_zone.core_vpc : key => merge(value, {
#       provider = "core-vpc"
#     })
#     }, {
#     for key, value in data.aws_route53_zone.self : key => merge(value, {
#       provider = "self"
#     })
#   })
validation_records_cloudfront = {
    for key, value in local.cloudfront_validation_records : key => {
      name   = value.name
      record = value.record
      type   = value.type
    } if value.zone.provider == "external"
  }

}

### Cloudfront Secret Creation
resource "random_password" "cloudfront" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "cloudfront" {
  # name        = "cloudfront-v1-secret-${var.application_name}-${formatdate("DDMMMYYYYhhmm", timestamp())}"
  name        = "cloudfront-v1-secret-${local.application_name}-${formatdate("DDMMMYYYYhhmm", timestamp())}"
  description = "Simple secret created by Terraform"
}

resource "aws_secretsmanager_secret_version" "cloudfront" {
  secret_id     = aws_secretsmanager_secret.cloudfront.id
  secret_string = random_password.cloudfront.result
}

# Importing the AWS secrets created previously using arn.
data "aws_secretsmanager_secret" "cloudfront" {
  arn = aws_secretsmanager_secret.cloudfront.arn
}

# Importing the AWS secret version created previously using arn.
data "aws_secretsmanager_secret_version" "cloudfront" {
  secret_id = data.aws_secretsmanager_secret.cloudfront.arn
}

### Cloudfront S3 bucket creation
resource "aws_s3_bucket" "cloudfront" { # Mirroring laa-cloudfront-logging-development in laa-dev
  # bucket = "laa-${var.application_name}-cloudfront-logging-${var.environment}"
  bucket = "laa-${local.application_name}-cloudfront-logging-${local.environment}"
  # force_destroy = true # Enable to recreate bucket deleting everything inside
  tags = merge(
    # var.tags,
    local.tags,
    {
      # Name = "laa-${var.application_name}-cloudfront-logging-${var.environment}"
      Name = "laa-${local.application_name}-cloudfront-logging-${local.environment}"
    }
  )
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket" "portalerrorpagebucket" {
  # bucket = "laa-${var.application_name}-errorpagebucket-${var.environment}"
  bucket = "laa-${local.application_name}-errorpagebucket-${local.environment}"
  # force_destroy = true # Enable to recreate bucket deleting everything inside
  tags = merge(
    # var.tags,
    local.tags,
    {
      # Name = "laa-${var.application_name}-errorpagebucket-${var.environment}"
      Name = "laa-${local.application_name}-errorpagebucket-${local.environment}"
    }
  )
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudfront" {
  bucket = aws_s3_bucket.cloudfront.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# resource "aws_s3_bucket_ownership_controls" "portalerrorpagebucket" {
#   bucket = aws_s3_bucket.portalerrorpagebucket.id
#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront" {
  bucket = aws_s3_bucket.cloudfront.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

# resource "aws_s3_bucket_server_side_encryption_configuration" "portalerrorpagebucket" {
#   bucket = aws_s3_bucket.portalerrorpagebucket.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
#   # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
#   lifecycle {
#     prevent_destroy = false
#   }
# }

resource "aws_s3_bucket_public_access_block" "cloudfront" {
  bucket = aws_s3_bucket.cloudfront.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

# resource "aws_s3_bucket_public_access_block" "portalerrorpagebucket" {
#   bucket = aws_s3_bucket.portalerrorpagebucket.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
#   # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
#   lifecycle {
#     prevent_destroy = false
#   }
# }

resource "aws_cloudfront_origin_access_identity" "portalerrorpagebucket" {
  comment = "portalerrorpagebucket"
}

data "aws_iam_policy_document" "portal_error_page_bucket_policy" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      aws_s3_bucket.portalerrorpagebucket.id,
    ]
  }
}

resource "aws_cloudfront_distribution" "external" {
#   http_version = var.cloudfront_http_version
  http_version  = "http2"
  origin {
    domain_name = aws_lb.external.dns_name
    origin_id   = aws_lb.external.id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.portalerrorpagebucket.cloudfront_access_identity_path
    }
    custom_origin_config {
      http_port                = 80 # This port was not defined in CloudFormation, but should not be used anyways, only required by Terraform
      https_port               = 443
    #   origin_protocol_policy   = var.cloudfront_origin_protocol_policy
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
    #   origin_read_timeout      = var.cloudfront_origin_read_timeout
      origin_read_timeout      = 60
    #   origin_keepalive_timeout = var.cloudfront_origin_keepalive_timeout
      origin_keepalive_timeout = 60
    }
    custom_header {
      name  = local.custom_header
      value = data.aws_secretsmanager_secret_version.cloudfront.secret_string
    }
  }
#   enabled = var.cloudfront_enabled
  enabled = true
#   aliases = [var.fqdn]
  aliases = [local.application_data.accounts[local.environment].fqdn]
  default_cache_behavior {
    target_origin_id = aws_lb.external.id
    # smooth_streaming = lookup(var.cloudfront_default_cache_behavior, "smooth_streaming", null)
    smooth_streaming = false
    default_ttl      = 0
    # allowed_methods  = lookup(var.cloudfront_default_cache_behavior, "allowed_methods", null)
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    # cached_methods   = lookup(var.cloudfront_default_cache_behavior, "cached_methods", null)
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
    #   query_string = lookup(var.cloudfront_default_cache_behavior, "forwarded_values_query_string", null)
      query_string = true
    #   headers      = lookup(var.cloudfront_default_cache_behavior, "forwarded_values_headers", null)
    #   headers        = ["Authorization", "CloudFront-Forwarded-Proto", "CloudFront-Is-Desktop-Viewer", "CloudFront-Is-Mobile-Viewer", "CloudFront-Is-SmartTV-Viewer", "CloudFront-Is-Tablet-Viewer", "CloudFront-Viewer-Country", "Host", "User-Agent"]
      cookies {
        # forward           = lookup(var.cloudfront_default_cache_behavior, "forwarded_values_cookies_forward", null)
        forward      = "all"
        # headers      = ["Authorization", "CloudFront-Forwarded-Proto", "CloudFront-Is-Desktop-Viewer", "CloudFront-Is-Mobile-Viewer", "CloudFront-Is-SmartTV-Viewer", "CloudFront-Is-Tablet-Viewer", "CloudFront-Viewer-Country", "Host", "User-Agent"]
        # whitelisted_names = lookup(var.cloudfront_default_cache_behavior, "forwarded_values_cookies_whitelisted_names", null)
        # not sure if this is needed for Portal
      }
    }
    # viewer_protocol_policy = lookup(var.cloudfront_default_cache_behavior, "viewer_protocol_policy", null)
    viewer_protocol_policy = "redirect-to-https"
  }

  #  ordered_cache_behavior_PortalErrorPageBucket {
  ordered_cache_behavior {
      target_origin_id = aws_s3_bucket.portalerrorpagebucket.id
      smooth_streaming = false
      path_pattern     = "/error-pages/*"
      min_ttl          = 0
      default_ttl      = 0
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["HEAD", "GET"]
      forwarded_values {
        query_string   = false
        cookies {
          forward      = "all"
        }
      }
      viewer_protocol_policy = "redirect-to-https"
    }

    # ordered_cache_behavior_LoadBalancer {
    ordered_cache_behavior {
      target_origin_id = aws_lb.external.id
      smooth_streaming = false
      path_pattern     = "*.png"
      min_ttl          = 0
      default_ttl      = 0
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["HEAD", "GET"]
      forwarded_values {
        query_string   = false
        headers        = ["Host", "User-Agent"]
        cookies {
          forward      = "all"
        }
      }
      viewer_protocol_policy = "redirect-to-https"
    }

    # ordered_cache_behavior_LoadBalancer {
    ordered_cache_behavior {
      target_origin_id = aws_lb.external.id
      smooth_streaming = false
      path_pattern     = "*.jpg"
      min_ttl          = 0
      default_ttl      = 0
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["HEAD", "GET"]
      forwarded_values {
        query_string   = false
        headers        = ["Host", "User-Agent"]
        cookies {
          forward      = "all"
        }
      }
      viewer_protocol_policy = "redirect-to-https"
    }

    # ordered_cache_behavior_LoadBalancer {
    ordered_cache_behavior {
      target_origin_id = aws_lb.external.id
      smooth_streaming = false
      path_pattern     = "*.gif"
      min_ttl          = 0
      default_ttl      = 0
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["HEAD", "GET"]
      forwarded_values {
        query_string   = false
        headers        = ["Host", "User-Agent"]
        cookies {
          forward      = "all"
        }
      }
      viewer_protocol_policy = "redirect-to-https"
    }

    # ordered_cache_behavior_LoadBalancer {
    ordered_cache_behavior {
      target_origin_id = aws_lb.external.id
      smooth_streaming = false
      path_pattern     = "*.css"
      min_ttl          = 0
      default_ttl      = 0
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["HEAD", "GET"]
      forwarded_values {
        query_string   = false
        headers        = ["Host", "User-Agent"]
        cookies {
          forward      = "all"
        }
      }
      viewer_protocol_policy = "redirect-to-https"
    }

    # ordered_cache_behavior_LoadBalancer {
    ordered_cache_behavior {
      target_origin_id = aws_lb.external.id
      smooth_streaming = false
      path_pattern     = "*.js"
      min_ttl          = 0
      default_ttl      = 0
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["HEAD", "GET"]
      forwarded_values {
        query_string   = false
        headers        = ["Host", "User-Agent"]
        cookies {
          forward      = "all"
        }
      }
      viewer_protocol_policy = "redirect-to-https"
    }

#   price_class = var.cloudfront_price_class
  price_class = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront.bucket_domain_name
    # prefix          = var.application_name
    prefix          = local.application_name
  }
  web_acl_id = aws_wafv2_web_acl.wafv2_acl.id

  restrictions {
    geo_restriction {
      # restriction_type = var.cloudfront_geo_restriction_type
      restriction_type = "none"
      # locations        = var.cloudfront_geo_restriction_location
      locations        = []
    }
  }

  # is_ipv6_enabled = var.cloudfront_is_ipv6_enabled
  is_ipv6_enabled = true

  # tags = var.tags
  tags = local.tags
}

###### Cloudfront Route53 Records
###### zones being created by Vlad for Portal
# resource "aws_route53_record" "portal_dns_record" {
#   # zone_id = aws_route53_zone.portal-dev-private.private.zone_id
#   zone_id  = data.aws_route53_zone.portal-dev-private["${local.application_data.accounts[local.environment].acm_domain_name}"].zone_id
#   name    = "portal.dev.legalservices.gov.uk"
#   type    = "A"
#   alias {
#     name                   = aws_cloudfront_distribution.external.id
#     zone_id                = "Z2FDTNDATAQYW2"
#     evaluate_target_health = true
#   }
# }


###### Cloudfront Cert
resource "aws_acm_certificate_validation" "cloudfront_certificate_validation" {
  count           = (length(local.validation_records_cloudfront) == 0 || local.external_validation_records_created) ? 1 : 0
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [
    for key, value in local.validation_records_cloudfront : replace(value.name, "/\\.$/", "")
  ]
  depends_on = [
    aws_route53_record.cloudfront_validation_core_network_services
    # aws_route53_record.cloudfront_validation_core_vpc,
    # aws_route53_record.cloudfront_validation_self
  ]
}

resource "aws_acm_certificate" "cloudfront" {
  # domain_name               = var.hosted_zone
  domain_name               = local.application_data.accounts[local.environment].acm_domain_name
  validation_method         = "DNS"
  provider                  = aws.us-east-1
  # subject_alternative_names = var.environment == "production" ? null : ["${var.application_name}.${var.business_unit}-${var.environment}.${var.hosted_zone}"]
  # subject_alternative_names = local.environment == "production" ? null : ["${local.application_name}.${local.networking[0].local.networking[0].business-unit}-${local.environment}.${local.portal_hosted_zone}"]
  # subject_alternative_names = local.environment == "production" ? null : [local.application_data.accounts[local.environment].fqdn]
  # subject_alternative_names = local.environment == "production" ? null : ["*.${local.application_data.accounts[local.environment].fqdn}"]
  subject_alternative_names = local.environment == "production" ? null : [local.application_data.accounts[local.environment].acm_alt_domain_name]
  # tags                      = var.tags
  tags                      = local.tags
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route53_record" "cloudfront_validation_core_network_services" {
  provider = aws.core-network-services
  for_each = {
    for key, value in local.cloudfront_validation_records : key => value if value.zone.provider == "core-network-services"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type

  # NOTE: value.zone is null indicates the validation zone could not be found
  # Ensure route53_zones variable contains the given validation zone or
  # explicitly provide the zone details in the validation variable.
  zone_id = each.value.zone.zone_id

  depends_on = [
    aws_acm_certificate.cloudfront
  ]
}

# # use core-vpc provider to validate business-unit domain
# resource "aws_route53_record" "cloudfront_validation_core_vpc" {
#   provider = aws.core-vpc
#   for_each = {
#     for key, value in local.cloudfront_validation_records : key => value if value.zone.provider == "core-vpc"
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = each.value.zone.zone_id

#   depends_on = [
#     aws_acm_certificate.cloudfront
#   ]
# }

# resource "aws_route53_record" "cloudfront-non-prod" {
#   count    = var.environment != "production" ? 1 : 0
#   provider = aws.core-vpc
#   zone_id  = var.external_zone_id
#   name     = var.fqdn
#   type     = "A"
#   alias {
#     name                   = aws_cloudfront_distribution.external.domain_name
#     zone_id                = aws_cloudfront_distribution.external.hosted_zone_id
#     evaluate_target_health = true
#   }
# }

# resource "aws_route53_record" "cloudfront-prod" {
#   count    = var.environment == "production" ? 1 : 0
#   provider = aws.core-network-services
#   zone_id  = var.production_zone_id
#   name     = var.fqdn
#   type     = "A"
#   alias {
#     name                   = aws_cloudfront_distribution.external.domain_name
#     zone_id                = aws_cloudfront_distribution.external.hosted_zone_id
#     evaluate_target_health = true
#   }
# }

# # assume any other domains are defined in the current workspace
# resource "aws_route53_record" "cloudfront_validation_self" {
#   for_each = {
#     for key, value in local.cloudfront_validation_records : key => value if value.zone.provider == "self"
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = each.value.zone.zone_id

#   depends_on = [
#     aws_acm_certificate.cloudfront
#   ]
# }