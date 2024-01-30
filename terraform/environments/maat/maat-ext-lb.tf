locals {
    existing_bucket_name = ""
    account_number = local.environment_management.account_ids[terraform.workspace]
    external_lb_idle_timeout = 65
    ext_lb_listener_protocol = "HTTP"
    ext_lb_ssl_policy    = "ELBSecurityPolicy-TLS-1-2-2017-01"
    ext_listener_custom_header = "X-Custom-Header-LAA-${upper(local.application_name)}"
}

# Terraform module which creates S3 Bucket resources for Load Balancer Access Logs on AWS.

module "lb-s3-access-logs" {
  count  = local.existing_bucket_name == "" ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.1.0"

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
  drop_invalid_header_fields = false

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


#######################################################################
# To be completed
#######################################################################

resource "aws_security_group" "external_lb" {
  name        = "${local.application_name}-external-lb-security-group"
  description = "App External ALB Security Group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_security_group_rule" "external_lb_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.external_lb.id
}

resource "aws_security_group_rule" "external_lb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.external_lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "external" {

  load_balancer_arn = aws_lb.external.arn
  port              = 443
  protocol        = local.ext_lb_listener_protocol
  ssl_policy      = local.ext_lb_listener_protocol == "HTTPS" ? local.ext_lb_ssl_policy : null
  certificate_arn = local.ext_lb_listener_protocol == "HTTPS" ? null : null # For HTTPS, this needs the ARN of the certificate from Mod Platform - aws_acm_certificate_validation.external_lb_certificate_validation[0].certificate_arn

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