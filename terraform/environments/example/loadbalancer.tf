###########################################################################################
#------------------------Comment out file if not required----------------------------------
###########################################################################################

# Build loadbalancer security group

resource "aws_security_group" "example_load_balancer_sg" {
  name        = "example-lb-sg"
  description = "controls access to load balancer"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("lb-sg-%s-%s-example", local.application_name, local.environment)) }
  )

  # Set up the ingress and egress parts of the security group
}
resource "aws_security_group_rule" "ingress_traffic_lb" {
  for_each          = local.application_data.example_ec2_sg_rules
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.example_load_balancer_sg.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}
resource "aws_security_group_rule" "egress_traffic_lb" {
  for_each                 = local.application_data.example_ec2_sg_rules
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.example_load_balancer_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.example_load_balancer_sg.id
}

# Build loadbalancer
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

  security_groups = [aws_security_group.example_load_balancer_sg.id]

  access_logs {
    bucket  = module.s3-bucket-lb.bucket.id
    prefix  = "test-lb"
    enabled = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-external-loadbalancer"
    }
  )
  depends_on = [aws_security_group.example_load_balancer_sg]
}
# Create the target group
resource "aws_lb_target_group" "target_group" {
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

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-tg-${local.environment}"
    }
  )
}

# Link target group to the EC2 instance on port 80
resource "aws_lb_target_group_attachment" "develop" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.lb_example_instance.id
  port             = 80
}

# Load blancer listener
resource "aws_lb_listener" "external" {
  load_balancer_arn = aws_lb.external.arn
  port              = local.application_data.accounts[local.environment].server_port
  protocol          = local.application_data.accounts[local.environment].lb_listener_protocol
  #checkov:skip=CKV_AWS_2: "protocol for lb set in application_variables"
  ssl_policy = local.application_data.accounts[local.environment].lb_listener_protocol == "HTTP" ? "" : "ELBSecurityPolicy-2016-08"
  #checkov:skip=CKV_AWS_103: "ssl_policy for lb set in application_variables"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# This will build on the core-vpc development account under platforms-development.modernisation-platform.service.justice.gov.uk, and route traffic back to example LB
resource "aws_route53_record" "example" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name = aws_lb.external.dns_name
    zone_id = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}

# Creation of a WAFv2
resource "aws_wafv2_web_acl" "external" {
  #checkov:skip=CKV2_AWS_31:Logging example commented out below, example is sound but no logging configuration for it to build.
  name  = "example-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "friendly-rule-metric-name"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "my-web-acl"
    sampled_requests_enabled   = false
  }
}

# Association code for WAFv2 to the LB
resource "aws_wafv2_web_acl_association" "web_acl_association_my_lb" {
  resource_arn = aws_lb.external.arn
  web_acl_arn  = aws_wafv2_web_acl.external.arn
}

# Logging for WAF, it's commented out because it wouldn't build, however it's a basic example.

#resource "aws_wafv2_web_acl_logging_configuration" "external" {
#  log_destination_configs = [aws_kinesis_firehose_delivery_stream.example.arn]
#  resource_arn            = aws_wafv2_web_acl.external.arn
#  redacted_fields {
#    single_header {
#      name = "user-agent"
#    }
#  }
#}



#################################################################################
######################### S3 Bucket required for logs  ##########################
#################################################################################
module "s3-bucket-lb" { #tfsec:ignore:aws-s3-enable-versioning
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.3.0"

  bucket_prefix      = "s3-bucket-example-lb"
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.bucket_policy_lb.json]

  # Enable bucket to be destroyed when not empty
  force_destroy = true
  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region = "eu-west-2"
  # replication_role_arn = module.s3-bucket-replication-role.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
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

  tags = merge(local.tags,
    { Name = lower(format("s3-bucket-%s-%s-example", local.application_name, local.environment)) }
  )
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

#################################################################################
#################### EC2 build for load balancer targets. #######################
#################################################################################

resource "aws_instance" "lb_example_instance" {
  #checkov:skip=CKV2_AWS_41:"IAM role is not implemented for this example EC2. SSH/AWS keys are not used either."
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type          = local.application_data.accounts[local.environment].instance_type
  ami                    = local.application_data.accounts[local.environment].ami_image_id
  vpc_security_group_ids = [aws_security_group.example_load_balancer_sg.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  monitoring             = true
  ebs_optimized          = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-example", local.application_name, local.environment)) }
  )
  depends_on = [aws_security_group.example_load_balancer_sg]
}
