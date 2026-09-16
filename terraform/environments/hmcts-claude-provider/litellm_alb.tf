resource "aws_security_group" "litellm_alb" {
  name_prefix = "litellm-alb-"
  description = "LiteLLM gateway load balancer"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "litellm_alb_https" {
  for_each = toset(local.application_data.accounts[local.environment].litellm_allowed_cidrs)

  security_group_id = aws_security_group.litellm_alb.id
  description       = "HTTPS from HMCTS Azure proxy"
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "litellm_alb_to_tasks" {
  security_group_id            = aws_security_group.litellm_alb.id
  description                  = "LiteLLM tasks"
  referenced_security_group_id = aws_security_group.litellm_task.id
  from_port                    = local.litellm_port
  to_port                      = local.litellm_port
  ip_protocol                  = "tcp"
}

#trivy:ignore:AVD-AWS-0053: this needs to be public
resource "aws_lb" "litellm" {
  #checkov:skip=CKV_AWS_91: "ELB access logging not required"
  #checkov:skip=CKV_AWS_150: "Deletion protection not required in development"
  #checkov:skip=CKV2_AWS_76: "WAF includes AWSManagedRulesKnownBadInputsRuleSet, Log4JRCE_BODY is set to count because prompts contain code"
  name                       = "litellm-gateway"
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [aws_security_group.litellm_alb.id]
  subnets                    = data.aws_subnets.shared-public.ids
  drop_invalid_header_fields = true
  enable_deletion_protection = local.is-production

  # Bedrock event streams carry no keepalives, so long model pauses must not trip the idle timeout
  idle_timeout = 900
}

resource "aws_lb_target_group" "litellm" {
  name                 = "litellm-gateway"
  port                 = local.litellm_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 60

  health_check {
    path                = "/health/liveliness"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "litellm_https" {
  load_balancer_arn = aws_lb.litellm.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.litellm.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.litellm.arn
  }
}
