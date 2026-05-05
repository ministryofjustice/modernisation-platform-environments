##############################################
### Application Load Balancer for RADIUS Portal
###
### Provides public HTTPS access to LinOTP
### self-service MFA enrollment portal
##############################################

##############################################
### ALB Security Group
##############################################

resource "aws_security_group" "radius_alb" {
  count = local.environment == "development" ? 1 : 0

  name_prefix = "${local.application_name}-${local.environment}-radius-alb-"
  description = "Security group for RADIUS portal ALB"
  vpc_id      = aws_vpc.workspaces[0].id

  # HTTPS from internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  # HTTP from internet (redirect to HTTPS)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet (redirects to HTTPS)"
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-radius-alb-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Separate egress rule to avoid circular dependency
resource "aws_security_group_rule" "radius_alb_to_radius_server" {
  count = local.environment == "development" ? 1 : 0

  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.radius_alb[0].id
  source_security_group_id = aws_security_group.radius_server[0].id
  description              = "HTTPS to RADIUS servers"
}

##############################################
### Application Load Balancer
##############################################

resource "aws_lb" "radius_portal" {
  count = local.environment == "development" ? 1 : 0

  name               = "${local.application_name}-${local.environment}-radius-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.radius_alb[0].id]
  subnets            = [aws_subnet.public_a[0].id, aws_subnet.public_b[0].id]

  enable_deletion_protection = false # For development
  enable_http2               = true

  tags = merge(
    local.tags,
    {
      "Name"    = "${local.application_name}-${local.environment}-radius-alb"
      "Purpose" = "RADIUS MFA Portal"
    }
  )
}

##############################################
### Target Group
##############################################

resource "aws_lb_target_group" "radius_portal" {
  count = local.environment == "development" ? 1 : 0

  name_prefix = "radmfa"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.workspaces[0].id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/manage"
    protocol            = "HTTPS"
    matcher             = "200,401" # 401 is OK (auth required for /manage)
  }

  deregistration_delay = 30

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-radius-tg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

##############################################
### Target Group Attachment
##############################################

resource "aws_lb_target_group_attachment" "radius_portal" {
  count = local.environment == "development" ? 1 : 0

  target_group_arn = aws_lb_target_group.radius_portal[0].arn
  target_id        = aws_instance.radius_server[0].id
  port             = 443
}

##############################################
### HTTPS Listener (Primary)
##############################################

resource "aws_lb_listener" "radius_https" {
  count = local.environment == "development" ? 1 : 0

  load_balancer_arn = aws_lb.radius_portal[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.radius_portal[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.radius_portal[0].arn
  }

  depends_on = [aws_acm_certificate_validation.radius_portal]

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-radius-https-listener"
    }
  )
}

##############################################
### HTTP Listener (Redirect to HTTPS)
##############################################

resource "aws_lb_listener" "radius_http" {
  count = local.environment == "development" ? 1 : 0

  load_balancer_arn = aws_lb.radius_portal[0].arn
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

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-radius-http-listener"
    }
  )
}
