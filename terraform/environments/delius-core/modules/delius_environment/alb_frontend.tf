resource "aws_security_group" "delius_frontend_alb_security_group" {
  name        = format("%s - Delius Core Frontend Load Balancer", var.env_name)
  description = "controls access to and from delius front-end load balancer"
  vpc_id      = var.account_config.shared_vpc_id
  tags        = local.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "delius_core_frontend_alb_ingress_https_allowlist" {
  security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  description       = "access into delius core frontend alb over https"
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "tcp"
  cidr_ipv4         = "81.134.202.29/32" # MoJ Digital VPN
}

resource "aws_vpc_security_group_ingress_rule" "delius_core_frontend_alb_ingress_https_global_protect_allowlist" {
  for_each          = toset(local.all_ingress_ips)
  security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  description       = "access into delius core frontend alb over https"
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "tcp"
  cidr_ipv4         = each.key # Global Protect VPN
}

resource "aws_vpc_security_group_egress_rule" "delius_core_frontend_alb_egress_to_ecs_cluster" {
  security_group_id            = aws_security_group.delius_frontend_alb_security_group.id
  description                  = "egress from delius core frontend alb to ecs cluster"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.cluster.id
}

locals {
  # use a diff app name only when env = training
  # to ensure alb is less than 32 chars
  # e.g. delius-core-training-weblogic-alb is 33 chars which AWS does now allow
  app_alias = var.env_name == "training" ? "delius" : var.app_name

  alb_name = "${local.app_alias}-${var.env_name}-weblogic-alb"
}

# tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "delius_core_frontend" {
  #checkov:skip=CKV_AWS_91 "ignore"
  #checkov:skip=CKV2_AWS_28 "ignore"

  name               = local.alb_name
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

# Listener rules
resource "aws_lb_listener_rule" "deny_mobiles_listener_rule" {
  listener_arn = aws_lb_listener.listener_https.arn
  priority     = 10
  condition {
    http_header {
      http_header_name = "User-Agent"
      values           = ["*Mobile*"]
    }
  }
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access is restricted to MoJ-issued laptops and PCs."
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "blocked_paths_listener_rule" {
  listener_arn = aws_lb_listener.listener_https.arn
  priority     = 20 # must be before ndelius_allowed_paths_rule
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

resource "aws_lb_listener_rule" "allowed_paths_listener_rule" {
  listener_arn = aws_lb_listener.listener_https.arn
  priority     = 30
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


resource "aws_lb_listener_rule" "homepage_listener_rule" {
  listener_arn = aws_lb_listener.listener_https.arn
  priority     = 50
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
