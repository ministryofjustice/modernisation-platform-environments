## Build ingress and egress rules
#locals {
#  loadbalancer_ingress_rules = {
#    "cluster_ec2_lb_ingress" = {
#      description     = "Cluster EC2 loadbalancer ingress rule"
#      from_port       = 80
#      to_port         = 80
#      protocol        = "tcp"
#      cidr_blocks     = [data.aws_vpc.shared.cidr_block]
#      security_groups = []
#    },
#    "cluster_ec2_bastion_ingress" = {
#      description     = "Cluster EC2 bastion ingress rule"
#      from_port       = 3389
#      to_port         = 3389
#      protocol        = "tcp"
#      cidr_blocks     = [data.aws_vpc.shared.cidr_block]
#      security_groups = []
#    }
#  }
#
#  loadbalancer_egress_rules = {
#    "cluster_ec2_lb_egress" = {
#      description     = "Cluster EC2 loadbalancer egress rule"
#      from_port       = 443
#      to_port         = 443
#      protocol        = "tcp"
#      cidr_blocks     = ["0.0.0.0/0"]
#      security_groups = []
#    }
#  }
#}
#
## Load balancer build using the module
#module "lb_access_logs_enabled" {
#  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer?ref=v2.1.1"
#  providers = {
#    # Here we use the default provider for the S3 bucket module, buck replication is disabled but we still
#    # Need to pass the provider to the S3 bucket module
#    aws.bucket-replication = aws
#  }
#  vpc_all = "${local.vpc_name}-${local.environment}"
#  #existing_bucket_name               = "my-bucket-name"
#  force_destroy_bucket       = true # enables destruction of logging bucket
#  application_name           = local.application_name
#  public_subnets             = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
#  loadbalancer_ingress_rules = local.loadbalancer_ingress_rules
#  loadbalancer_egress_rules  = local.loadbalancer_egress_rules
#  tags                       = local.tags
#  account_number             = local.environment_management.account_ids[terraform.workspace]
#  region                     = "eu-west-2"
#  enable_deletion_protection = false
#  idle_timeout               = 60
#}
#
## Create the target group
#resource "aws_lb_target_group" "target_group_module" {
#  name                 = "${local.application_name}-tg-mlb-${local.environment}"
#  port                 = local.application_data.accounts[local.environment].server_port
#  protocol             = "HTTP"
#  vpc_id               = data.aws_vpc.shared.id
#  target_type          = "instance"
#  deregistration_delay = 30
#
#  stickiness {
#    type = "lb_cookie"
#  }
#  #checkov:skip=CKV_AWS_261: "health_check defined below, but not picked up"
#  health_check {
#    healthy_threshold   = "5"
#    interval            = "120"
#    protocol            = "HTTP"
#    unhealthy_threshold = "2"
#    matcher             = "200-499"
#    timeout             = "5"
#  }
#}
#
## Build loadbalancer security group
#
#resource "aws_security_group" "example_load_balancer_sg" {
#  name        = "example-lb-sg"
#  description = "controls access to load balancer"
#  vpc_id      = data.aws_vpc.shared.id
#  tags = merge(local.tags,
#    { Name = lower(format("lb-sg-%s-%s-example", local.application_name, local.environment)) }
#  )
#
#  # Set up the ingress and egress parts of the security group
#}
#resource "aws_security_group_rule" "ingress_traffic_lb" {
#  for_each          = local.application_data.example_ec2_sg_rules
#  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
#  from_port         = each.value.from_port
#  protocol          = each.value.protocol
#  security_group_id = aws_security_group.example_load_balancer_sg.id
#  to_port           = each.value.to_port
#  type              = "ingress"
#  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
#}
#resource "aws_security_group_rule" "egress_traffic_lb" {
#  for_each                 = local.application_data.example_ec2_sg_rules
#  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
#  from_port                = each.value.from_port
#  protocol                 = each.value.protocol
#  security_group_id        = aws_security_group.example_load_balancer_sg.id
#  to_port                  = each.value.to_port
#  type                     = "egress"
#  source_security_group_id = aws_security_group.example_load_balancer_sg.id
#}
#
## Build loadbalancer
##tfsec:ignore:aws-elb-alb-not-public as the external lb needs to be public.
#resource "aws_lb" "external" {
#  name               = "${local.application_name}-loadbalancer"
#  load_balancer_type = "application"
#  subnets            = data.aws_subnets.shared-public.ids
#  #checkov:skip=CKV_AWS_150:Short-lived example environment, hence no need for deletion protection
#  enable_deletion_protection = false
#  # allow 60*4 seconds before 504 gateway timeout for long-running DB operations
#  idle_timeout               = 240
#  drop_invalid_header_fields = true
#
#  security_groups = [aws_security_group.example_load_balancer_sg.id]
#
#  access_logs {
#    bucket  = module.s3-bucket.bucket.id
#    prefix  = "test-lb"
#    enabled = true
#  }
#
#  tags = merge(
#    local.tags,
#    {
#      Name = "${local.application_name}-external-loadbalancer"
#    }
#  )
#
#  depends_on = [aws_security_group.example_ec2_sg]
#}
## Create the target group
#resource "aws_lb_target_group" "target_group" {
#  name                 = "${local.application_name}-tg-${local.environment}"
#  port                 = local.application_data.accounts[local.environment].server_port
#  protocol             = "HTTP"
#  vpc_id               = data.aws_vpc.shared.id
#  target_type          = "instance"
#  deregistration_delay = 30
#
#  stickiness {
#    type = "lb_cookie"
#  }
#  #checkov:skip=CKV_AWS_261: "health_check defined below, but not picked up"
#  health_check {
#    healthy_threshold   = "5"
#    interval            = "120"
#    protocol            = "HTTP"
#    unhealthy_threshold = "2"
#    matcher             = "200-499"
#    timeout             = "5"
#  }
#
#  tags = merge(
#    local.tags,
#    {
#      Name = "${local.application_name}-tg-${local.environment}"
#    }
#  )
#}
#
## Link target group to the EC2 instance on port 80
#resource "aws_lb_target_group_attachment" "develop" {
#  target_group_arn = aws_lb_target_group.target_group.arn
#  target_id        = aws_instance.develop.id
#  port             = 80
#}
#
## Load blancer listener
#resource "aws_lb_listener" "external" {
#  load_balancer_arn = aws_lb.external.arn
#  port              = local.application_data.accounts[local.environment].server_port
#  protocol          = local.application_data.accounts[local.environment].lb_listener_protocol
#  #checkov:skip=CKV_AWS_2: "protocol for lb set in application_variables"
#  ssl_policy = local.application_data.accounts[local.environment].lb_listener_protocol == "HTTP" ? "" : "ELBSecurityPolicy-2016-08"
#  #checkov:skip=CKV_AWS_103: "ssl_policy for lb set in application_variables"
#
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.target_group.arn
#  }
#}
#
## This will build on the core-vpc development account under platforms-development.modernisation-platform.service.justice.gov.uk, and route traffic back to example LB
#resource "aws_route53_record" "example" {
#  provider = aws.core-vpc
#  zone_id = data.aws_route53_zone.external.zone_id
#  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#  type    = "A"
#
#  alias {
#    name = aws_lb.external.dns_name
#    zone_id = aws_lb.external.zone_id
#    evaluate_target_health = true
#  }
#}
#
## Creation of a WAFv2
#
#resource "aws_wafv2_web_acl" "external" {
#  #checkov:skip=CKV2_AWS_31:Logging example commented out below, example is sound but no logging configuration for it to build.
#  name  = "example-web-acl"
#  scope = "REGIONAL"
#
#  default_action {
#    allow {}
#  }
#
#  rule {
#    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
#    priority = 1
#
#    override_action {
#      none {}
#    }
#
#    statement {
#      managed_rule_group_statement {
#        name        = "AWSManagedRulesKnownBadInputsRuleSet"
#        vendor_name = "AWS"
#      }
#    }
#
#    visibility_config {
#      cloudwatch_metrics_enabled = false
#      metric_name                = "friendly-rule-metric-name"
#      sampled_requests_enabled   = false
#    }
#  }
#
#  visibility_config {
#    cloudwatch_metrics_enabled = false
#    metric_name                = "my-web-acl"
#    sampled_requests_enabled   = false
#  }
#}
#
## Association code for WAFv2 to the LB
#
#resource "aws_wafv2_web_acl_association" "web_acl_association_my_lb" {
#  resource_arn = aws_lb.external.arn
#  web_acl_arn  = aws_wafv2_web_acl.external.arn
#}
#
## Logging for WAF, it's commented out because it wouldn't build, however it's a basic example.
#
##resource "aws_wafv2_web_acl_logging_configuration" "external" {
##  log_destination_configs = [aws_kinesis_firehose_delivery_stream.example.arn]
##  resource_arn            = aws_wafv2_web_acl.external.arn
##  redacted_fields {
##    single_header {
##      name = "user-agent"
##    }
##  }
##}
#
