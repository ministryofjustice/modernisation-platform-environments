resource "aws_lb_target_group" "frontend" {
  name     = "vcms-frontend"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.account_info.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200-399"
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400
  }

  target_type = "ip"

  tags = local.tags
}

# ALB
resource "aws_lb" "frontend" {
  name               = "frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = local.account_config.public_subnet_ids

  enable_deletion_protection = false
  idle_timeout               = 60

  tags = local.tags
}

# HTTP Listener
# resource "aws_lb_listener" "frontend_http" {
#   load_balancer_arn = aws_lb.frontend.arn

#   port     = 80
#   protocol = "HTTP"

#   # Anything that doesn't match the NAT Gateway rule gets rejected.
#   default_action {
#     type = "fixed-response"

#     fixed_response {
#       content_type = "text/plain"
#       message_body = "Forbidden"
#       status_code  = "403"
#     }
#   }
# }

# resource "aws_lb_listener_rule" "http_redirect" {
#   listener_arn = aws_lb_listener.frontend_http.arn
#   priority     = 100

#   action {
#     type = "redirect"

#     redirect {
#       protocol    = "HTTPS"
#       port        = "443"
#       host        = "#{host}"
#       path        = "/#{path}"
#       query       = "#{query}"
#       status_code = "HTTP_301"
#     }
#   }

#   condition {
#     source_ip {
#       values = local.mp_natgw_ips
#     }
#   }

#   condition {
#     host_header {
#       values = [
#         "www.dev.victim-case-management.service.justice.gov.uk"
#       ]
#     }
#   }
# }


# HTTPS Listener
resource "aws_lb_listener" "frontend_https" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Legacy Redirect Rule
# resource "aws_lb_listener_rule" "legacy_redirect" {
#   listener_arn = aws_lb_listener.frontend_https.arn
#   priority     = 100

#   action {
#     type = "redirect"
#     redirect {
#       host        = "vcms.hmpps-development.modernisation-platform.service.justice.gov.uk"
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }

#   condition {
#     host_header {
#       values = ["www.dev.victim-case-management.service.justice.gov.uk"]
#     }
#   }
# }