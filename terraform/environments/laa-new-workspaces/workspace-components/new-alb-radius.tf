##############################################
### Application Load Balancer for RADIUS Portal
###
### Provides HTTPS access to LinOTP
### self-service MFA enrollment portal
### Access restricted to Global Protect Alpha VPN
##############################################

##############################################
### ALB Security Group
##############################################

resource "aws_security_group" "radius_alb" {

  name_prefix = "${local.application_name}-${local.environment}-radius-alb-"
  description = "Security group for RADIUS portal ALB"
  vpc_id      = aws_vpc.workspaces.id

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

resource "aws_security_group_rule" "radius_alb_https_from_vpn" {

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.global_protect_alpha_vpn_cidrs
  security_group_id = aws_security_group.radius_alb.id
  description       = "HTTPS from Global Protect Alpha VPN"
}

resource "aws_security_group_rule" "radius_alb_http_from_vpn" {

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = local.global_protect_alpha_vpn_cidrs
  security_group_id = aws_security_group.radius_alb.id
  description       = "HTTP from Global Protect Alpha VPN (redirects to HTTPS)"
}

# Egress rule for ECS LinOTP tasks
resource "aws_security_group_rule" "radius_alb_to_ecs_linotp" {

  type                     = "egress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.radius_alb.id
  source_security_group_id = aws_security_group.ecs_linotp3.id
  description              = "HTTP to ECS LinOTP tasks"
}

##############################################
### Application Load Balancer
##############################################

resource "aws_lb" "radius_portal" {

  name_prefix        = "radmfa"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.radius_alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

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
### HTTPS Listener (Primary)
##############################################

resource "aws_lb_listener" "radius_https" {

  load_balancer_arn = aws_lb.radius_portal.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.radius_portal.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.linotp3_portal.arn
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

  load_balancer_arn = aws_lb.radius_portal.arn
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