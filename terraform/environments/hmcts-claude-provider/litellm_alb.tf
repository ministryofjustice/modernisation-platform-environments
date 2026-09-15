resource "aws_security_group" "litellm_alb" {
  name_prefix = "litellm-alb-"
  description = "LiteLLM gateway load balancer"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }
}

#trivy:ignore:AVD-AWS-0107: public gateway, requests are authenticated with LiteLLM keys and filtered by WAF
resource "aws_vpc_security_group_ingress_rule" "litellm_alb_https" {
  #checkov:skip=CKV_AWS_260: public gateway, requests are authenticated with LiteLLM keys and filtered by WAF
  security_group_id = aws_security_group.litellm_alb.id
  description       = "HTTPS from anywhere"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

#trivy:ignore:AVD-AWS-0107: redirected to HTTPS
resource "aws_vpc_security_group_ingress_rule" "litellm_alb_http" {
  #checkov:skip=CKV_AWS_260: redirected to HTTPS
  security_group_id = aws_security_group.litellm_alb.id
  description       = "HTTP from anywhere for redirect to HTTPS"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
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

resource "aws_lb_listener" "litellm_http" {
  #checkov:skip=CKV_AWS_2: "Redirects to HTTPS"
  #checkov:skip=CKV_AWS_103: "Redirects to HTTPS"
  load_balancer_arn = aws_lb.litellm.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
