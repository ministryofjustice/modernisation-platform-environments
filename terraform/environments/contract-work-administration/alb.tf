locals {
  lb_logs_bucket                = local.application_data.accounts[local.environment].lb_access_logs_existing_bucket_name
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

  tags = local.tags
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
# External CWA ELB
####################################

resource "aws_lb" "external" {
  name                       = "${upper(local.application_name_short)}-LoadBalancer"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.external_lb.id]
  subnets                    = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]
  enable_deletion_protection = local.lb_enable_deletion_protection
  idle_timeout               = local.external_lb_idle_timeout
  enable_http2               = false
  # drop_invalid_header_fields = true

  access_logs {
    bucket  = local.lb_logs_bucket != "" ? local.lb_logs_bucket : module.elb-logs-s3[0].bucket.id
    prefix  = "${local.application_name}-LoadBalancer"
    enabled = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-LoadBalancer"
    },
  )
}

resource "aws_lb_listener" "external" {

  load_balancer_arn = aws_lb.external.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.load_balancer.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external.arn
  }

  tags = local.tags

}

resource "aws_lb_listener_rule" "external" {
  listener_arn = aws_lb_listener.external.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_target_group" "external" {
  name                          = "${local.application_name_short}-TargetGroup"
  port                          = 8050
  protocol                      = "HTTP"
  vpc_id                        = data.aws_vpc.shared.id
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
    local.tags,
    {
      Name = "${local.application_name}-TargetGroup"
    },
  )

}

resource "aws_lb_target_group_attachment" "external" {
  target_group_arn = aws_lb_target_group.external.arn
  target_id        = aws_instance.app1.id
  port             = 8050
}

resource "aws_lb_target_group_attachment" "external2" {
  count            = contains(["development", "test"], local.environment) ? 0 : 1
  target_group_arn = aws_lb_target_group.external.arn
  target_id        = aws_instance.app2[0].id
  port             = 8050
}


############################################
# External CWA ELB Security Group MOJ Prefix List
############################################

resource "aws_ec2_managed_prefix_list" "moj_ip_allowlist" {
  name           = "moj-aws-ip-allowlist"
  address_family = "IPv4"
  max_entries    = 13

  entry {
    cidr        = "18.130.39.94/32"
    description = "Non-Prod Workspaces NAT IPs"
  }

  entry {
    cidr        = "35.177.145.193/32"
    description = "Non-Prod Workspaces NAT IPs"
  }

  entry {
    cidr        = "35.176.127.232/32"
    description = "Non-Prod Workspaces NAT IPs"
  }

  entry {
    cidr        = "52.56.212.11/32"
    description = "Prod WorkSpaces NAT IPs"
  }

  entry {
    cidr        = "35.176.254.38/32"
    description = "Prod WorkSpaces NAT IPs"
  }

  entry {
    cidr        = "35.177.173.197/32"
    description = "Prod WorkSpaces NAT IPs"
  }

  entry {
    cidr        = "3.9.183.160/32"
    description = "AppStream NAT IP"
  }

  entry {
    cidr        = "35.178.209.113/32"
    description = "Cloud Platform"
  }

  entry {
    cidr        = "3.8.51.207/32"
    description = "Cloud Platform"
  }

  entry {
    cidr        = "35.177.252.54/32"
    description = "Cloud Platform"
  }

  tags = {
    Name        = "moj-aws-ip-allowlist"
    Environment = "all"
  }
}

############################################
# External CWA ELB Security Group LAA Prefix List
############################################

resource "aws_ec2_managed_prefix_list" "laa_ip_allowlist" {
  name           = "laa-ip-allowlist"
  address_family = "IPv4"
  max_entries    = 13

  entry {
    cidr        = "51.149.249.0/29"
    description = "Allowlist entry"
  }

  entry {
    cidr        = "194.33.249.0/29"
    description = "Allowlist entry"
  }

  entry {
    cidr        = "51.149.249.32/29"
    description = "Allowlist entry"
  }

  entry {
    cidr        = "194.33.248.0/29"
    description = "Allowlist entry"
  }

  entry {
    cidr        = "20.49.214.199/32"
    description = "Allowlist entry"
  }

  entry {
    cidr        = "20.49.214.228/32"
    description = "Allowlist entry"
  }

  entry {
    cidr        = "20.26.11.71/32"
    description = "Allowlist entry"
  }

  entry {
    cidr        = "20.26.11.108/32"
    description = "Allowlist entry"
  }

  entry {
    cidr        = "128.77.75.64/26"
    description = "Allowlist entry"
  }

  entry {
    cidr        = "18.169.147.172/32"
    description = "Allowlist entry"
  }

  entry {
    cidr        = "35.176.93.186/32"
    description = "Allowlist entry"
  }

  entry {
    cidr        = "18.130.148.126/32"
    description = "Allowlist entry"
  }

  entry {
    cidr        = "35.176.148.126/32"
    description = "Allowlist entry"
  }

  tags = {
    Name        = "laa-ip-allowlist"
    Environment = "all"
  }
}

############################################
# External CWA ELB Security Group
############################################

resource "aws_security_group" "external_lb" {
  name        = "${local.application_name}-external-lb-security-group"
  description = "${local.application_name} ALB Security Group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "external_lb_inbound_laa_allowlist" {
  security_group_id = aws_security_group.external_lb.id
  prefix_list_id    = aws_ec2_managed_prefix_list.laa_ip_allowlist.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "external_lb_inbound_MOJ_allowlist" {
  security_group_id = aws_security_group.external_lb.id
  prefix_list_id    = aws_ec2_managed_prefix_list.moj_ip_allowlist.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "external_lb_outbound" {
  security_group_id = aws_security_group.external_lb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
