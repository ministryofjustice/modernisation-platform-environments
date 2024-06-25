locals {
  listener_headers = toset(var).app_urls
  listener_rules = {
    admin_access_1 = {
      path_patterns = ["*/Admin*", "*/admin*"]
      source_ips    = ["195.59.75.0/24", "194.33.192.0/25"]
    }
    admin_access_2 = {
      path_patterns = ["*/Admin*", "*/admin*"]
      source_ips    = ["194.33.193.0/25", "194.33.196.0/25"]
    }
    admin_access_3 = {
      path_patterns = ["*/Admin*", "*/admin*"]
      source_ips    = ["194.33.197.0/25"]
    }
    secure_access_1 = {
      path_patterns = ["*/Secure*", "*/secure*"]
      source_ips    = ["195.59.75.0/24", "194.33.192.0/25"]
    }
    secure_access_2 = {
      path_patterns = ["*/Secure*", "*/secure*"]
      source_ips    = ["194.33.193.0/25"]
    }
  }
  combined_rules = merge([
    for header in local.listener_headers : {
      for rule_name, rule in local.listener_rules :
      "${header}_${rule_name}" => {
        host_header   = "${header}.*"
        path_patterns = rule.path_patterns
        source_ips    = rule.source_ips
      }
    }
  ]...)
}

resource "aws_security_group" "tribunals_lb_sg" {
  name        = "${var.app_name}-load-balancer-sg"
  description = "${var.app_name} control access to the load balancer"
  vpc_id      = var.vpc_shared_id

}

resource "aws_security_group_rule" "ingress-http" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.tribunals_lb_sg.id
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "ingress-https" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.tribunals_lb_sg.id
  to_port           = 443
  type              = "ingress"
}
resource "aws_security_group_rule" "egress-all" {
  from_port         = -1
  protocol          = "all"
  security_group_id = aws_security_group.tribunals_lb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = -1
  type              = "egress"
}

resource "aws_lb" "tribunals_lb" {
  name                       = "${var.app_name}-lb"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.tribunals_lb_sg.id]
  subnets                    = var.subnets_shared_public_ids
  enable_deletion_protection = false
  internal                   = false
}

resource "aws_lb_target_group" "tribunals_target_group" {
  for_each             = local.listener_headers
  name                 = "${each.key}-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_shared_id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    healthy_threshold   = "3"
    interval            = "15"
    protocol            = "HTTP"
    unhealthy_threshold = "3"
    matcher             = "200-499"
    timeout             = "10"
  }
}

resource "aws_lb_listener" "tribunals_lb" {
  load_balancer_arn = aws_lb.tribunals_lb.arn
  port              = var.application_data.server_port_2
  protocol          = var.application_data.lb_listener_protocol_2
  ssl_policy        = var.application_data.lb_listener_protocol_2 == "HTTP" ? "" : "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tribunals_target_group.arn
  }
}

resource "aws_lb_listener" "tribunals_lb_health" {
  load_balancer_arn = aws_lb.tribunals_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tribunals_target_group.arn
  }
}

resource "aws_lb_listener_certificate" "tribunals_lb_cert" {
  for_each        = toset(var.certificate_arns)
  certificate_arn = each.key
  listener_arn    = aws_lb_listener.tribunals_lb.arn
}

resource "aws_wafv2_web_acl_association" "web_acl_association_my_lb" {
  resource_arn = aws_lb.tribunals_lb.arn
  web_acl_arn  = var.waf_arn
}

resource "aws_lb_listener_rule" "tribunals_lb_listener_rule_1" {
  for_each     = local.combined_rules
  listener_arn = aws_lb_listener.tribunals_lb.arn
  priority     = index(keys(local.combined_rules), each.key) + 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tribunals_target_group[each.key].arn
  }
  condition {
    host_header {
      values = [each.value.host_header]
    }
  }
  condition {
    path_pattern {
      values = [each.value.path_patterns]
    }
  }
  condition {
    source_ip {
      values = [each.value.source_ips]
    }
  }
}

resource "aws_lb_listener_rule" "admin_secure_fixed_response" {
  listener_arn = aws_lb_listener.tribunals_lb.arn
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/html"
      message_body = "<h1>Secure Page</h1> <h3>This area of the website now requires elevated security.</h3> <br> <h3>If you believe you should be able to access this page please send an email to: - dts-legacy-apps-support-team@hmcts.net</h3>"
      status_code  = "403"
    }
  }
  condition {
    path_pattern {
      values = ["/Admin*", "/admin*", "/Secure*", "/secure*"]
    }
  }
}