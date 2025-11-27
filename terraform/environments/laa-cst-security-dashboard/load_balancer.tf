# Build loadbalancer security group

resource "aws_security_group" "cst_load_balancer_sg" {
  name        = "example-lb-sg"
  description = "controls access to load balancer"
  vpc_id      = data.aws_vpc.shared.id
  tags        = { Name = lower(format("lb-sg-%s-%s-", local.application_name, local.environment)) }

  # Set up the ingress and egress parts of the security group
}
resource "aws_security_group_rule" "ingress_traffic_lb" {
  for_each          = local.application_data.example_ec2_sg_rules
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.cst_load_balancer_sg.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}
resource "aws_security_group_rule" "egress_traffic_lb" {
  for_each                 = local.application_data.example_ec2_sg_rules
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.cst_load_balancer_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.cst_load_balancer_sg.id
}

# # Build loadbalancer
#tfsec:ignore:aws-elb-alb-not-public as the external lb needs to be public.
resource "aws_lb" "external" {
  name               = "${local.application_name}-loadbalancer"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.shared-public.ids
  #checkov:skip=CKV_AWS_150:Short-lived example environment, hence no need for deletion protection
  enable_deletion_protection = false
  # allow 60*4 seconds before 504 gateway timeout for long-running DB operations
  idle_timeout               = 240
  drop_invalid_header_fields = true

  security_groups = [aws_security_group.cst_load_balancer_sg.id]

  access_logs {
    bucket  = module.s3-bucket-lb.bucket.id
    prefix  = "test-lb"
    enabled = true
  }

  tags       = { Name = "${local.application_name}-external-loadbalancer" }
  depends_on = [aws_security_group.cst_load_balancer_sg]
}
# # Create the target group
resource "aws_lb_target_group" "target_group" {
  #checkov:skip=CKV_AWS_378: "Ensure AWS Load Balancer doesn't use HTTP protocol"
  name                 = "${local.application_name}-tg-${local.environment}"
  port                 = local.application_data.accounts[local.environment].server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }
  #checkov:skip=CKV_AWS_261: "health_check defined below, but not picked up"
  health_check {
    healthy_threshold   = "5"
    interval            = "120"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = { Name = "${local.application_name}-tg-${local.environment}" }
  lifecycle {
    create_before_destroy = true
  }
}



# Load balancer listener
resource "aws_lb_listener" "external" {
  load_balancer_arn = aws_lb.external.arn
  port              = local.application_data.accounts[local.environment].server_port
  protocol          = local.application_data.accounts[local.environment].lb_listener_protocol
  #checkov:skip=CKV_AWS_2: "protocol for lb set in application_variables"
  ssl_policy = local.application_data.accounts[local.environment].lb_listener_protocol == "HTTP" ? "" : "ELBSecurityPolicy-TLS13-1-2-2021-06"
  #checkov:skip=CKV_AWS_103: "ssl_policy for lb set in application_variables"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# # # This will build on the core-vpc development account under platforms-development.modernisation-platform.service.justice.gov.uk, and route traffic back to example LB
resource "aws_route53_record" "example" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"

  alias {
    name                   = aws_lb.external.dns_name
    zone_id                = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}

# # Association code for WAFv2 to the LB
resource "aws_wafv2_web_acl_association" "web_acl_association_my_lb" {
  resource_arn = aws_lb.external.arn
  web_acl_arn  = aws_wafv2_web_acl.external.arn
}


#################################################################################
######################### S3 Bucket required for logs  ##########################
#################################################################################
module "s3-bucket-lb" {
  #tfsec:ignore:aws-s3-enable-versioning
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=568694e50e03630d99cb569eafa06a0b879a1239" #v7.1.0
  bucket_prefix      = "s3-bucket-example-lb"
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.bucket_policy_lb.json]

  # Enable bucket to be destroyed when not empty
  force_destroy = true
  replication_enabled = false
  replication_region = "eu-west-2"
  replication_role_arn = module.s3-bucket-replication-role.role.arn
  providers = {
    aws.bucket-replication = aws
  }

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

  tags = { Name = lower(format("s3-bucket-%s-%s-example", local.application_name, local.environment)) }
}

data "aws_iam_policy_document" "bucket_policy_lb" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${module.s3-bucket-lb.bucket.arn}/test-lb/AWSLogs/*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.default_lb.arn]
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

    resources = ["${module.s3-bucket-lb.bucket.arn}/test-lb/AWSLogs/*"]

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
      module.s3-bucket-lb.bucket.arn
    ]
  }
}

data "aws_iam_policy_document" "s3-access-policy-lb" {
  version = "2012-10-17"
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "rds.amazonaws.com",
        "ec2.amazonaws.com",
      ]
    }
  }
}

data "aws_elb_service_account" "default_lb" {}
