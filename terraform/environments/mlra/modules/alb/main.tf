locals {
  loadbalancer_ingress_rules = {
    "lb_ingress" = {
      description     = "Loadbalancer ingress rule from MoJ VPN"
      from_port       = var.security_group_ingress_from_port
      to_port         = var.security_group_ingress_to_port
      protocol        = var.security_group_ingress_protocol
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }
  loadbalancer_egress_rules = {
    "lb_egress" = {
      description     = "Loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }

  ## Variables used by certificate validation, as part of the cloudfront, cert and route 53 record configuration
  domain_types = { for dvo in aws_acm_certificate.external_lb.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  domain_name_main   = [for k, v in local.domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  domain_name_sub    = [for k, v in local.domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  domain_record_main = [for k, v in local.domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  domain_record_sub  = [for k, v in local.domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  domain_type_main   = [for k, v in local.domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  domain_type_sub    = [for k, v in local.domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]

  domain_name   = "${var.application_name}.${var.business_unit}-${var.environment}.modernisation-platform.service.justice.gov.uk"
  ip_set_list   = [for ip in split("\n", chomp(file("${path.module}/waf_ip_set.txt"))) : ip]
  custom_header = "X-Custom-Header-LAA-${upper(var.application_name)}"

}


data "aws_vpc" "shared" {
  tags = {
    "Name" = var.vpc_all
  }
}

# Terraform module which creates S3 Bucket resources for Load Balancer Access Logs on AWS.

module "s3-bucket" {
  count  = var.existing_bucket_name == "" ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws.bucket-replication
  }
  bucket_prefix       = "${var.application_name}-lb-access-logs"
  bucket_policy       = [data.aws_iam_policy_document.bucket_policy.json]
  replication_enabled = false
  versioning_enabled  = true
  force_destroy       = var.force_destroy_bucket
  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = var.tags
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}/${var.application_name}/AWSLogs/${var.account_number}/*" : "${module.s3-bucket[0].bucket.arn}/${var.application_name}/AWSLogs/${var.account_number}/*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.default.arn]
    }
  }
  statement {
    sid = "AWSLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}/${var.application_name}/AWSLogs/${var.account_number}/*" : "${module.s3-bucket[0].bucket.arn}/${var.application_name}/AWSLogs/${var.account_number}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      var.existing_bucket_name != "" ? "arn:aws:s3:::${var.existing_bucket_name}" : module.s3-bucket[0].bucket.arn
    ]
  }
}

data "aws_elb_service_account" "default" {}

#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "loadbalancer" {
  #checkov:skip=CKV_AWS_150:preventing destroy can be controlled outside of the module
  #checkov:skip=CKV2_AWS_28:WAF is configured outside of the module for more flexibility
  name                       = "${var.application_name}-application-external-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.lb.id]
  subnets                    = [var.public_subnets[0], var.public_subnets[1], var.public_subnets[2]]
  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.existing_bucket_name != "" ? var.existing_bucket_name : module.s3-bucket[0].bucket.id
    prefix  = var.application_name
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-alb"
    },
  )
}

resource "aws_security_group" "lb" {
  name        = "${var.application_name}-lb-security-group"
  description = "Controls access to the loadbalancer"
  vpc_id      = data.aws_vpc.shared.id

  dynamic "ingress" {
    for_each = local.loadbalancer_ingress_rules
    content {
      description     = lookup(ingress.value, "description", null)
      from_port       = lookup(ingress.value, "from_port", null)
      to_port         = lookup(ingress.value, "to_port", null)
      protocol        = lookup(ingress.value, "protocol", null)
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
    }
  }

  dynamic "egress" {
    for_each = local.loadbalancer_egress_rules
    content {
      description     = lookup(egress.value, "description", null)
      from_port       = lookup(egress.value, "from_port", null)
      to_port         = lookup(egress.value, "to_port", null)
      protocol        = lookup(egress.value, "protocol", null)
      cidr_blocks     = lookup(egress.value, "cidr_blocks", null)
      security_groups = lookup(egress.value, "security_groups", null)
    }
  }
}

## Cloudfront


resource "random_password" "cloudfront" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "cloudfront" {
  name        = "cloudfront-v1-secret-${var.application_name}"
  description = "Simple secret created by AWS CloudFormation to be shared between ALB and CloudFront"
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

resource "aws_acm_certificate" "cloudfront" {
  domain_name       = var.acm_cert_domain_name
  validation_method = "DNS"
  provider = aws.us-east-1


  subject_alternative_names = var.environment == "production" ? null : [local.domain_name]

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# TODO This was a centralised bucket in LAA Landing Zone - do we want one for each application/env account in MP? Yes for now

resource "aws_s3_bucket" "cloudfront" { # Mirroring laa-cloudfront-logging-development in laa-dev
  bucket = "laa-${var.application_name}-cloudfront-logging-${var.environment}"
  # force_destroy = true # Enable to recreate bucket deleting everything inside
  tags = merge(
    var.tags,
    {
      Name = "laa-${var.application_name}-cloudfront-logging-${var.environment}"
    }
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront" {
  bucket = aws_s3_bucket.cloudfront.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront" {
  bucket = aws_s3_bucket.cloudfront.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# TODO IS this required for CloudFront cert?
# resource "aws_acm_certificate_validation" "cloudfront" {
#   certificate_arn         = aws_acm_certificate.cloudfront.arn
#   validation_record_fqdns = [aws_route53_record.aws_route53_record.fqdn]
# }

resource "aws_cloudfront_distribution" "external" {
  http_version = "http2"
  origin {
    domain_name              = aws_lb.loadbalancer.dns_name
    origin_id                = aws_lb.loadbalancer.id
    custom_origin_config {
      http_port = 80   # TODO confirm the ports since http_port was not defined in CloudFormation
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout = 60
      origin_keepalive_timeout = 60
    }
    custom_header {
      name = local.custom_header
      value = data.aws_secretsmanager_secret_version.cloudfront.secret_string
    }
  }
  enabled = true
  aliases = [local.domain_name]
  default_cache_behavior {
    target_origin_id = aws_lb.loadbalancer.id
    smooth_streaming = false
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
      query_string = true
      cookies {
        forward = "whitelist"
        whitelisted_names = ["AWSALB", "JSESSIONID"]
      }
      headers = ["Authorization", "CloudFront-Forwarded-Proto", "CloudFront-Is-Desktop-Viewer", "CloudFront-Is-Mobile-Viewer", "CloudFront-Is-SmartTV-Viewer", "CloudFront-Is-Tablet-Viewer", "CloudFront-Viewer-Country", "Host", "User-Agent"]
    }
    viewer_protocol_policy = "https-only"
  }

  # Other cache behaviors are processed in the order in which they're listed in the CloudFront console or, if you're using the CloudFront API, the order in which they're listed in the DistributionConfig element for the distribution.

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    target_origin_id = aws_lb.loadbalancer.id
    smooth_streaming = false
    path_pattern     = "*.png"
    min_ttl                = 0
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
      query_string = false
      headers      = ["Host", "User-Agent"]
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "https-only"
  }
  # Cache behavior with precedence 1
  ordered_cache_behavior {
    target_origin_id = aws_lb.loadbalancer.id
    smooth_streaming = false
    path_pattern     = "*.jpg"
    min_ttl                = 0
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
      query_string = false
      headers      = ["Host", "User-Agent"]
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "https-only"
  }
  # Cache behavior with precedence 2
  ordered_cache_behavior {
    target_origin_id = aws_lb.loadbalancer.id
    smooth_streaming = false
    path_pattern     = "*.gif"
    min_ttl                = 0
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
      query_string = false
      headers      = ["Host", "User-Agent"]
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "https-only"
  }
  # Cache behavior with precedence 3
  ordered_cache_behavior {
    target_origin_id = aws_lb.loadbalancer.id
    smooth_streaming = false
    path_pattern     = "*.css"
    min_ttl                = 0
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
      query_string = false
      headers      = ["Host", "User-Agent"]
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "https-only"
  }
  # Cache behavior with precedence 4
  ordered_cache_behavior {
    target_origin_id = aws_lb.loadbalancer.id
    smooth_streaming = false
    path_pattern     = "*.js"
    min_ttl                = 0
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["HEAD", "GET"]
    forwarded_values {
      query_string = false
      headers      = ["Host", "User-Agent"]
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "https-only"
  }
  price_class = "PriceClass_100"
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cloudfront.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront.bucket_domain_name
    prefix          = var.application_name
  }
  web_acl_id = aws_waf_web_acl.waf_acl.id

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  is_ipv6_enabled = true

  tags = var.tags

}

## WAF

resource "aws_waf_ipset" "allow" {
  name = "${upper(var.application_name)} Manual Allow Set"

  # Ranges from https://github.com/ministryofjustice/moj-ip-addresses/blob/master/moj-cidr-addresses.yml
  # disc_internet_pipeline, disc_dom1, moj_digital_wifi, petty_france_office365, petty_france_wifi, ark_internet, gateway_proxies

  dynamic "ip_set_descriptors" {
    for_each = local.ip_set_list
    content {
      type  = "IPV4"
      value = ip_set_descriptors.value
    }
  }
}

resource "aws_waf_ipset" "block" {
  name = "${upper(var.application_name)} Manual Block Set"
}

resource "aws_waf_rule" "allow" {
  name        = "${upper(var.application_name)} Manual Allow Rule"
  metric_name = "${upper(var.application_name)}ManualAllowRule"

  predicates {
    data_id = aws_waf_ipset.allow.id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_waf_rule" "block" {
  name        = "${upper(var.application_name)} Manual Block Rule"
  metric_name = "${upper(var.application_name)}ManualBlockRule"

  predicates {
    data_id = aws_waf_ipset.block.id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_waf_web_acl" "waf_acl" {
  name        = "${upper(var.application_name)} Whitelisting Requesters"
  metric_name = "${upper(var.application_name)}WhitelistingRequesters"
  default_action {
    type = "BLOCK"
  }
  rules {
    action {
      type = "ALLOW"
    }
    priority = 1
    rule_id  = aws_waf_rule.allow.id
  }
  rules {
    action {
      type = "BLOCK"
    }
    priority = 2
    rule_id  = aws_waf_rule.block.id
  }
}

# TODO Do we need an S3 bucket for store WAF logs? There is currently no logging_configuration.

## ALB Listener

resource "aws_acm_certificate" "external_lb" {
  domain_name       = var.acm_cert_domain_name
  validation_method = "DNS"

  subject_alternative_names = var.environment == "production" ? null : [local.domain_name]

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external_lb.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}

## Route 53 for Cloudfront
resource "aws_route53_record" "cloudfront" {
  # for_each = {
  #   for dvo in aws_acm_certificate.external_lb.domain_validation_options : dvo.domain_name => {
  #     name   = dvo.resource_record_name
  #     record = dvo.resource_record_value
  #     type   = dvo.resource_record_type
  #   }
  # }
  provider = aws.core-vpc
  zone_id  = var.external_zone_id
  name     = local.domain_name
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.external.domain_name
    zone_id                = aws_cloudfront_distribution.external.hosted_zone_id
    evaluate_target_health = true
  }

  # records  = [each.value.record]
}

# Use core-network-services provider to validate top-level domain
resource "aws_route53_record" "external_validation" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = var.services_zone_id
}

# Use core-vpc provider to validate business-unit domain
resource "aws_route53_record" "external_validation_subdomain" {
  count    = length(local.domain_name_sub)
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[count.index]
  records         = [local.domain_record_sub[count.index]]
  ttl             = 60
  type            = local.domain_type_sub[count.index]
  zone_id         = var.external_zone_id
}

######################

# TODO This resource is required because otherwise Error: failed to read schema for module.alb.null_resource.always_run in registry.terraform.io/hashicorp/null: failed to instantiate provider
# When the whole stack is recreated this can be removed
resource "null_resource" "always_run" {
  triggers = {
    timestamp = "${timestamp()}"
  }
}

resource "aws_lb_listener" "alb_listener" {

  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = var.listener_port
  #checkov:skip=CKV_AWS_2:The ALB protocol is HTTP
  protocol        = var.listener_protocol #tfsec:ignore:aws-elb-http-not-used
  ssl_policy      = var.listener_protocol == "HTTPS" ? var.alb_ssl_policy : null
  certificate_arn = var.listener_protocol == "HTTPS" ? aws_acm_certificate_validation.external.certificate_arn : null # This needs the ARN of the certificate from Mod Platform

  # default_action {
  #   type = "forward"
  #   # during phase 1 of migration into modernisation platform, an effort
  #   # is being made to retain the current application url in order to
  #   # limit disruption to the application architecture itself. therefore,
  #   # the current laa alb which is performing tls termination is going to
  #   # forward queries on here. this also means that waf and cdn resources
  #   # are retained in laa. the cdn there adds a custom header to the query,
  #   # with the alb there then forwarding those permitted queries on:
  #   #
  #   # - Type: fixed-response
  #   #   FixedResponseConfig:
  #   #     ContentType: text/plain
  #   #     MessageBody: Access Denied - must access via CloudFront
  #   #     StatusCode: '403'
  #   #
  #   # in the meantime, therefore, we simply forward queries to a target
  #   # group. however, in another phase of the migration, where cdn resources
  #   # are carried into the modernisation platform, the above configuration
  #   # may need to be applied.
  #   #
  #   # see: https://docs.google.com/document/d/15BUaNNx6SW2fa6QNzdMUWscWWBQ44YCiFz-e3SOwouQ
  #
  #   target_group_arn = aws_lb_target_group.alb_target_group.arn
  # }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    # type = "fixed-response"
    # fixed_response {
    #   content_type = "text/plain"
    #   message_body = "Access Denied - must access via CloudFront"
    #   status_code  = 403
    # }
  }

  tags = var.tags

}

# resource "aws_lb_listener_rule" "alb_listener_rule" {
#   listener_arn = aws_lb_listener.alb_listener.arn
#   priority     = 1
#
#   # during phase 1 of migration into modernisation platform, an effort
#   # is being made to retain the current application url in order to
#   # limit disruption to the application architecture itself. therefore,
#   # the current laa alb which is performing tls termination is going to
#   # forward queries on here. this also means that waf and cdn resources
#   # are retained in laa. the cdn there adds a custom header to the query,
#   # with the alb there then forwarding those permitted queries on:
#   #
#   # Actions:
#   #   - Type: forward
#   #     TargetGroupArn: !Ref 'TargetGroup'
#   # Conditions:
#   #   - Field: http-header
#   #     HttpHeaderConfig:
#   #     HttpHeaderName: X-Custom-Header-LAA-MLRA
#   #     Values:
#   #       - '{{resolve:secretsmanager:cloudfront-secret-MLRA}}'
#   #
#   # in the meantime, therefore, we are simply forwarding traffic to a
#   # target group here. However, in another phase of the migration, where
#   # cdn resources are carried into modernisation platform, the above
#   # configuration is very likely going to be required.
#   #
#   # see: https://docs.google.com/document/d/15BUaNNx6SW2fa6QNzdMUWscWWBQ44YCiFz-e3SOwouQ
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.alb_target_group.arn
#   }
#
#   # condition {
#   #   path_pattern {
#   #     values = ["/"]
#   #   }
#   # }
#
#   condition {
#     http_header {
#       http_header_name = local.custom_header
#       values           = [data.aws_secretsmanager_secret_version.cloudfront.secret_string]
#     }
#   }
# }

resource "aws_lb_target_group" "alb_target_group" {
  name                 = "${var.application_name}-alb-tg"
  port                 = var.target_group_port
  protocol             = var.target_group_protocol
  vpc_id               = var.vpc_id
  deregistration_delay = var.target_group_deregistration_delay
  health_check {
    interval            = var.healthcheck_interval
    path                = var.healthcheck_path
    protocol            = var.healthcheck_protocol
    timeout             = var.healthcheck_timeout
    healthy_threshold   = var.healthcheck_healthy_threshold
    unhealthy_threshold = var.healthcheck_unhealthy_threshold
  }
  stickiness {
    enabled         = var.stickiness_enabled
    type            = var.stickiness_type
    cookie_duration = var.stickiness_cookie_duration
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-alb-tg"
    },
  )

}

resource "aws_athena_database" "lb-access-logs" {
  name   = "loadbalancer_access_logs"
  bucket = var.existing_bucket_name != "" ? var.existing_bucket_name : module.s3-bucket[0].bucket.id
  encryption_configuration {
    encryption_option = "SSE_S3"
  }
}

resource "aws_athena_named_query" "main" {
  name     = "${var.application_name}-create-table"
  database = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "${path.module}/templates/create_table.sql",
    {
      bucket     = var.existing_bucket_name != "" ? var.existing_bucket_name : module.s3-bucket[0].bucket.id
      account_id = var.account_number
      region     = var.region
    }
  )
}

resource "aws_athena_workgroup" "lb-access-logs" {
  name = "${var.application_name}-lb-access-logs"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = var.existing_bucket_name != "" ? "s3://${var.existing_bucket_name}/output/" : "s3://${module.s3-bucket[0].bucket.id}/output/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.application_name}-lb-access-logs"
    }
  )

}
