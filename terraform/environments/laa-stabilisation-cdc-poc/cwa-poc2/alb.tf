locals {
  lb_logs_bucket                = var.application_data.accounts[local.environment].lb_access_logs_existing_bucket_name
  lb_enable_deletion_protection = false
  external_lb_idle_timeout      = 900
  force_destroy_lb_logs_bucket  = true
}

####################################
# ELB Access Logging
####################################

module "elb-logs-s3" {
  count  = local.lb_logs_bucket == "" ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"


  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix       = "${local.application_name_short}-lb-access-logs"
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

  tags = var.tags
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [local.lb_logs_bucket != "" ? "arn:aws:s3:::${local.lb_logs_bucket}/*" : "${module.elb-logs-s3[0].bucket.arn}/*"]
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

    resources = [local.lb_logs_bucket != "" ? "arn:aws:s3:::${local.lb_logs_bucket}/*" : "${module.elb-logs-s3[0].bucket.arn}/*"]

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
# Internal CWA ALB
####################################

resource "aws_lb" "internal" {
  name               = "${upper(local.application_name_short)}-Internal-LB"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_lb.id]
  subnets            = [var.private_subnet_a_id, var.private_subnet_b_id, var.private_subnet_c_id]

  enable_deletion_protection = true
  idle_timeout               = 60
  enable_http2               = true

  tags = merge(
    var.tags,
    {
      Name = "${local.application_name_short}-Internal-LB"
    },
  )
}

resource "aws_security_group" "internal_lb" {
  name        = "${local.application_name_short}-internal-lb-sg"
  description = "Internal ALB security group - restricted to LAA WorkSpaces"
  vpc_id      = var.shared_vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${local.application_name_short}-internal-lb-sg"
    },
  )
}

resource "aws_vpc_security_group_ingress_rule" "internal_lb_inbound" {
  security_group_id = aws_security_group.internal_lb.id
  cidr_ipv4         = "10.200.0.0/20"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "internal_lb_outbound" {
  security_group_id = aws_security_group.internal_lb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

####################################
# Internal ALB Target Group & Listener
####################################

resource "aws_lb_target_group" "internal" {
  name                          = "${local.application_name_short}-Internal-TG"
  port                          = 8050
  protocol                      = "HTTP"
  vpc_id                        = var.shared_vpc_id
  deregistration_delay          = 10
  load_balancing_algorithm_type = "least_outstanding_requests"

  health_check {
    interval            = 15
    path                = "/OA_HTML/AppsLocalLogin.jsp"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.application_name_short}-Internal-TG"
    },
  )
}

resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.load_balancer.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal.arn
  }

  tags = var.tags
}

# Attach the app servers to the internal ALB
resource "aws_lb_target_group_attachment" "internal_app1" {
  target_group_arn = aws_lb_target_group.internal.arn
  target_id        = aws_instance.app1.id
  port             = 8050
}

# resource "aws_lb_target_group_attachment" "internal_app2" {
#   count            = contains(["development", "testing"], local.environment) ? 0 : 1
#   target_group_arn = aws_lb_target_group.internal.arn
#   target_id        = aws_instance.app2[0].id
#   port             = 8050
# }
