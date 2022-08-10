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

# Build loadbalancer #tfsec:ignore:aws-elb-alb-not-public as the external lb needs to be public.
resource "aws_lb" "external" {
  name                       = "${local.application_name}-loadbalancer"
  load_balancer_type         = "application"
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = true
  # allow 60*4 seconds before 504 gateway timeout for long-running DB operations
  idle_timeout               = 240
  drop_invalid_header_fields = true

  security_groups = [aws_security_group.example_load_balancer_sg.id]

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "test-lb"
    enabled = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-external-loadbalancer"
    }
  )

  depends_on = [aws_security_group.example_ec2_sg]
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
  target_id        = aws_instance.develop.id
  port             = 80
}

# Load blancer listener
resource "aws_lb_listener" "external" {
  load_balancer_arn = aws_lb.external.arn
  port              = local.application_data.accounts[local.environment].server_port
  protocol          = local.application_data.accounts[local.environment].lb_listener_protocol
  #checkov:skip=CKV_AWS_2: "protocol for lb set in application_variables"
  ssl_policy = local.application_data.accounts[local.environment].lb_ssl_policy
  #checkov:skip=CKV_AWS_103: "ssl_policy for lb set in application_variables"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
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

