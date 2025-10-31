locals {
  existing_bucket_name       = ""
  account_number             = local.environment_management.account_ids[terraform.workspace]
  external_lb_idle_timeout   = 65
  ext_lb_listener_protocol   = "HTTPS"
  ext_lb_ssl_policy          = "ELBSecurityPolicy-TLS-1-2-2017-01"
  ext_listener_custom_header = "X-Custom-Header-LAA-${upper(local.application_name)}"
  # TODO This URL to access Internal ALB needs to be confirmed, and may need another hosted zone for production
  int_lb_url = local.environment == "production" ? "${local.application_url_prefix}-lb.${data.aws_route53_zone.production-network-services.name}" : "${local.application_url_prefix}-lb.${data.aws_route53_zone.external.name}"
}

# Terraform module which creates S3 Bucket resources for Load Balancer Access Logs on AWS.

module "lb-s3-access-logs" {
  count  = local.existing_bucket_name == "" ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=474f27a3f9bf542a8826c76fb049cc84b5cf136f"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix       = "${local.application_name}-lb-access-logs"
  bucket_policy       = [data.aws_iam_policy_document.bucket_policy.json]
  replication_enabled = false
  versioning_enabled  = true
  force_destroy       = true
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

  tags = local.tags
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [local.existing_bucket_name != "" ? "arn:aws:s3:::${local.existing_bucket_name}/${local.application_name}/AWSLogs/${local.account_number}/*" : "${module.lb-s3-access-logs[0].bucket.arn}/${local.application_name}/AWSLogs/${local.account_number}/*"]
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

    resources = [local.existing_bucket_name != "" ? "arn:aws:s3:::${local.existing_bucket_name}/${local.application_name}/AWSLogs/${local.account_number}/*" : "${module.lb-s3-access-logs[0].bucket.arn}/${local.application_name}/AWSLogs/${local.account_number}/*"]

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
      local.existing_bucket_name != "" ? "arn:aws:s3:::${local.existing_bucket_name}" : module.lb-s3-access-logs[0].bucket.arn
    ]
  }
}

data "aws_elb_service_account" "default" {}

resource "aws_lb" "external" {
  name                       = "${local.application_name}-external-load-balancer"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.external_lb.id]
  subnets                    = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]
  enable_deletion_protection = local.application_data.accounts[local.environment].ext_lb_enable_deletion_protection
  idle_timeout               = local.external_lb_idle_timeout
  drop_invalid_header_fields = true

  access_logs {
    bucket  = local.existing_bucket_name != "" ? local.existing_bucket_name : module.lb-s3-access-logs[0].bucket.id
    prefix  = local.application_name
    enabled = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-external-load-balancer"
    },
  )
}

resource "aws_security_group" "external_lb" {
  name        = "${local.application_name}-external-lb-security-group"
  description = "App External ALB Security Group"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-external-lb-security-group"
    }
  )
}
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group_rule" "external_lb_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  security_group_id = aws_security_group.external_lb.id
}

resource "aws_security_group_rule" "external_lb_egress" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.maat_ecs_security_group.id
  security_group_id        = aws_security_group.external_lb.id
}

resource "aws_lb_listener" "external" {

  load_balancer_arn = aws_lb.external.arn
  port              = 443
  protocol          = local.ext_lb_listener_protocol
  ssl_policy        = local.ext_lb_listener_protocol == "HTTPS" ? local.ext_lb_ssl_policy : null
  certificate_arn   = local.ext_lb_listener_protocol == "HTTPS" ? aws_acm_certificate_validation.load_balancers.certificate_arn : null

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied - must access via CloudFront"
      status_code  = 403
    }
  }

  tags = local.tags

}

resource "aws_lb_listener_rule" "external" {
  listener_arn = aws_lb_listener.external.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external.arn
  }

  condition {
    http_header {
      http_header_name = local.ext_listener_custom_header
      values           = [data.aws_secretsmanager_secret_version.cloudfront.secret_string]
    }
  }
}

resource "aws_lb_target_group" "external" {
  name                 = "${local.application_name}-external-target-group"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  deregistration_delay = 30
  health_check {
    interval            = 15
    path                = "/ccmt-web/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 10800 # 3 hours in seconds
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-external-target-group"
    },
  )

}

#######################################################
# Certification and Route53 for LBs
#######################################################

resource "aws_acm_certificate" "load_balancers" {
  domain_name               = local.application_data.accounts[local.environment].cloudfront_domain_name
  validation_method         = "DNS"
  subject_alternative_names = local.environment == "production" ? [local.int_lb_url] : [local.int_lb_url, local.lower_env_cloudfront_url]
  tags                      = local.tags
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route53_record" "load_balancers_external_validation" {
  provider = aws.core-network-services

  count           = local.environment == "production" ? 0 : 1
  allow_overwrite = true
  name            = local.lbs_domain_name_main[0]
  records         = local.lbs_domain_record_main
  ttl             = 60
  type            = local.lbs_domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "load_balancers_external_validation_subdomain_1" {
  provider = aws.core-vpc

  count           = local.environment == "production" ? 0 : 1
  allow_overwrite = true
  name            = local.lbs_domain_name_sub[0]
  records         = [local.lbs_domain_record_sub[0]]
  ttl             = 60
  type            = local.lbs_domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_route53_record" "load_balancers_external_validation_subdomain_2" {
  provider = aws.core-vpc

  count           = local.environment == "production" ? 0 : 1
  allow_overwrite = true
  name            = local.lbs_domain_name_sub[1]
  records         = [local.lbs_domain_record_sub[1]]
  ttl             = 60
  type            = local.lbs_domain_type_sub[1]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "load_balancers" {
  certificate_arn         = aws_acm_certificate.load_balancers.arn
  validation_record_fqdns = [local.lbs_domain_name_main[0], local.lbs_domain_name_sub[0], local.lbs_domain_name_sub[1]]
}