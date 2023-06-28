locals {
  lb_logs_bucket = local.application_data.accounts[local.environment].lb_access_logs_existing_bucket_name
  account_number = local.environment_management.account_ids[terraform.workspace]
  external_lb_idle_timeout = 65
  enable_deletion_protection = true
  external_lb_port = 80 #TODO This needs changing to 443 once Cert and CloudFront has been set up
  custom_header = "X-Custom-Header-LAA-Portal"
  force_destroy_lb_logs_bucket = true
}


####################################
# ELB Access Logging
####################################

module "elb-logs-s3" {
  count  = local.lb_logs_bucket == "" ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.4.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix       = "${local.application_name}-lb-access-logs"
  bucket_policy       = [data.aws_iam_policy_document.bucket_policy.json]
  replication_enabled = false
  versioning_enabled  = true
  force_destroy       = local.force_destroy_lb_logs_bucket
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
    resources = [local.lb_logs_bucket != "" ? "arn:aws:s3:::${local.lb_logs_bucket}/${local.application_name}/AWSLogs/${local.account_number}/*" : "${module.elb-logs-s3[0].bucket.arn}/${local.application_name}/AWSLogs/${local.account_number}/*"]
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

    resources = [local.lb_logs_bucket != "" ? "arn:aws:s3:::${local.lb_logs_bucket}/${local.application_name}/AWSLogs/${local.account_number}/*" : "${module.elb-logs-s3[0].bucket.arn}/${local.application_name}/AWSLogs/${local.account_number}/*"]

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
      local.lb_logs_bucket != "" ? "arn:aws:s3:::${local.lb_logs_bucket}" : module.elb-logs-s3[0].bucket.arn
    ]
  }
}

data "aws_elb_service_account" "default" {}

####################################
# External Portal ELB to OHS
####################################

resource "aws_lb" "external" {
  name                       = "${local.application_name}-external-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.external_lb.id]
  subnets                    = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]
  enable_deletion_protection = local.enable_deletion_protection
  idle_timeout               = local.external_lb_idle_timeout
  # drop_invalid_header_fields = true

  access_logs {
    bucket  = local.lb_logs_bucket != "" ? local.lb_logs_bucket : module.elb-logs-s3[0].bucket.id
    prefix  = local.application_name
    enabled = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-external-lb"
    },
  )
}

resource "aws_lb_listener" "external" {

  load_balancer_arn = aws_lb.external.arn
  port              = local.external_lb_port
  protocol        = "HTTP" #TODO This needs changing to HTTPS once Cert and CloudFront has been set up
  ssl_policy      = null # TODO This needs changing once Cert and CloudFront has been set up
  certificate_arn = null # TODO This needs changing once Cert and CloudFront has been set up

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external.arn
  }

  # TODO This needs using once Cert and CloudFront has been set up. Remove the forward action block above
  # default_action {
  #   type = "fixed-response"
  #   fixed_response {
  #     content_type = "text/plain"
  #     message_body = "Access Denied - must access via CloudFront"
  #     status_code  = 403
  #   }
  # }

  tags = local.tags

}

# TODO To be enabled once Cert and CloudFront has been set up
# resource "aws_lb_listener_rule" "external" {
#   listener_arn = aws_lb_listener.external.arn
#   priority     = 100
#
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.external.arn
#   }
#
#   condition {
#     http_header {
#       http_header_name = local.custom_header
#       values           = [data.aws_secretsmanager_secret_version.cloudfront.secret_string]
#     }
#   }
# }

resource "aws_lb_target_group" "external" {
  name                 = "${local.application_name}-ohs-target-group"
  port                 = 7777
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  # deregistration_delay = local.target_group_deregistration_delay
  load_balancing_algorithm_type = "least_outstanding_requests"
  health_check {
    interval            = 5
    path                = "/LAAPortal/pages/home.jsp"
    protocol            = "HTTP"
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher = 302
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ohs-target-group"
    },
  )

}

resource "aws_lb_target_group_attachment" "ohs1" {
  target_group_arn = aws_lb_target_group.external.arn
  target_id        = aws_instance.ohs_instance_1.id
  port             = 7777
}

resource "aws_lb_target_group_attachment" "ohs2" {
  count             = contains(["development", "testing"], local.environment) ? 0 : 1
  target_group_arn = aws_lb_target_group.external.arn
  target_id        = aws_instance.ohs_instance_2[0].id
  port             = 7777
}


############################################
# External Portal ELB Security Group
############################################

resource "aws_security_group" "external_lb" {
  name        = "${local.application_name}-external-lb-security-group"
  description = "${local.application_name} external alb security group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "external_lb_inbound" {
  security_group_id = aws_security_group.external_lb.id
  description       = "Allows HTTPS traffic in from Cloudfront (filtered by WAF)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = local.external_lb_port
  ip_protocol       = "tcp"
  to_port           = local.external_lb_port
}

resource "aws_vpc_security_group_egress_rule" "external_lb_outbound" {
  security_group_id = aws_security_group.external_lb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
