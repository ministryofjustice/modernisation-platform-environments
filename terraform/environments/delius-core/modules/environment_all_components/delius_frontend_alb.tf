locals {
  frontend_url = "${var.env_name}.${var.account_config.dns_suffix}"
}
resource "aws_security_group" "delius_frontend_alb_security_group" {
  name        = format("%s - Delius Core Frontend Load Balancer", var.env_name)
  description = "controls access to and from delius front-end load balancer"
  vpc_id      = var.account_config.shared_vpc_id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "delius_core_frontend_alb_ingress_https_allowlist" {
  security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  description       = "access into delius core frontend alb over https"
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "tcp"
  cidr_ipv4         = "81.134.202.29/32" # MoJ Digital VPN
}

resource "aws_vpc_security_group_ingress_rule" "delius_core_frontend_alb_ingress_http_allowlist" {
  security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  description       = "access into delius core frontend alb over http (will redirect)"
  from_port         = "80"
  to_port           = "80"
  ip_protocol       = "tcp"
  cidr_ipv4         = "81.134.202.29/32" # MoJ Digital VPN
}

resource "aws_vpc_security_group_ingress_rule" "delius_core_frontend_alb_ingress_https_global_protect_allowlist" {
  security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  description       = "access into delius core frontend alb over https"
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "tcp"
  cidr_ipv4         = "35.176.93.186/32" # Global Protect VPN
}

resource "aws_vpc_security_group_ingress_rule" "delius_core_frontend_alb_ingress_http_global_protect_allowlist" {
  security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  description       = "access into delius core frontend alb over http (will redirect)"
  from_port         = "80"
  to_port           = "80"
  ip_protocol       = "tcp"
  cidr_ipv4         = "35.176.93.186/32" # Global Protect VPN
}

#resource "aws_vpc_security_group_egress_rule" "delius_core_frontend_alb_egress_to_service" {
#  security_group_id            = aws_security_group.delius_frontend_alb_security_group.id
#  description                  = "access delius core frontend service from alb"
#  from_port                    = var.weblogic_config.frontend_container_port
#  to_port                      = var.weblogic_config.frontend_container_port
#  ip_protocol                  = "tcp"
#  referenced_security_group_id = aws_security_group.weblogic_service.id
#}

# tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "delius_core_frontend" {
  # checkov:skip=CKV_AWS_91
  # checkov:skip=CKV2_AWS_28

  name               = "${var.app_name}-${var.env_name}-weblogic-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.delius_frontend_alb_security_group.id]
  subnets            = var.account_config.public_subnet_ids

  enable_deletion_protection = false
  drop_invalid_header_fields = true
}


resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = aws_lb.delius_core_frontend.id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = local.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener" "listener_http" {
  load_balancer_arn = aws_lb.delius_core_frontend.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      path        = var.environment_config.homepage_path
    }
  }
}

#resource "aws_lb_target_group" "delius_core_frontend_target_group" {
#  # checkov:skip=CKV_AWS_261
#
#  name                 = var.weblogic_config.frontend_fully_qualified_name
#  port                 = var.weblogic_config.frontend_container_port
#  protocol             = "HTTP"
#  vpc_id               = var.account_config.shared_vpc_id
#  target_type          = "ip"
#  deregistration_delay = 30
#  tags                 = local.tags
#
#  stickiness {
#    type = "lb_cookie"
#  }
#
#  health_check {
#    path                = "/NDelius-war/delius/JSP/healthcheck.jsp?ping"
#    healthy_threshold   = "5"
#    interval            = "300"
#    protocol            = "HTTP"
#    unhealthy_threshold = "5"
#    matcher             = "200-499"
#    timeout             = "5"
#  }
#}

# Listener rules
resource "aws_lb_listener_rule" "homepage_listener_rule" {
  listener_arn = aws_lb_listener.listener_https.arn
  condition {
    path_pattern {
      values = ["/"]
    }
  }
  action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_302"
      path        = var.environment_config.homepage_path
    }
  }
  depends_on = [aws_lb_listener_rule.blocked_paths_listener_rule]
}

resource "aws_lb_listener_rule" "allowed_paths_listener_rule" {
  listener_arn = aws_lb_listener.listener_https.arn
  condition {
    path_pattern {
      values = [
        "/NDelius*",
        "/jspellhtml/*"
      ]
    }
  }
  action {
    type             = "forward"
    target_group_arn = module.weblogic.target_group_arn
  }
  depends_on = [aws_lb_listener_rule.blocked_paths_listener_rule]
}

resource "aws_lb_listener_rule" "blocked_paths_listener_rule" {
  listener_arn = aws_lb_listener.listener_https.arn
  priority     = 10 # must be before ndelius_allowed_paths_rule
  condition {
    path_pattern {
      values = [
        "/NDelius*/delius/a4j/g/3_3_3.Final*DATA*", # mitigates CVE-2018-12533
      ]
    }
  }
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
    }
  }
}
