# public

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
# resource "aws_lb_listener" "frontend" {
#   load_balancer_arn = aws_lb.frontend.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.frontend.arn
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
resource "aws_lb_listener_rule" "legacy_redirect" {
  listener_arn = aws_lb_listener.frontend_https.arn
  priority     = 100

  action {
    type = "redirect"
    redirect {
      host        = "vcms.hmpps-development.modernisation-platform.service.justice.gov.uk"
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = ["www.dev.victim-case-management.service.justice.gov.uk"]
    }
  }
}

# private

resource "aws_lb_target_group" "frontend_private" {
  name     = "vcms-frontend-private"
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


# HTTPS Listener
resource "aws_lb_listener" "frontend_private_https" {
  load_balancer_arn = aws_lb.frontend_private.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_private.arn
  }
}