resource "aws_security_group" "ancillary_alb_security_group" {
  name        = format("%s - Delius Core Ancilliary Load Balancer", var.env_name)
  description = "controls access to and from delius front-end load balancer"
  vpc_id      = var.account_config.shared_vpc_id
  tags        = local.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "ancillary_alb_ingress_https_global_protect_allowlist" {
  for_each          = toset(local.all_ingress_ips)
  security_group_id = aws_security_group.ancillary_alb_security_group.id
  description       = "Access into alb over https"
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "tcp"
  cidr_ipv4         = each.key # Global Protect VPN
}

# Necessary for Unit tests from Legacy
resource "aws_vpc_security_group_ingress_rule" "test_ingress" {
  #checkov:skip=CKV_AWS_23 "ignore"
  for_each = var.env_name == "test" ? {
    for cidr in local.legacy_test_natgw_ips : cidr => cidr
  } : {}

  security_group_id = aws_security_group.ancillary_alb_security_group.id
  cidr_ipv4         = each.value
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "tcp"
}

# resource "aws_vpc_security_group_ingress_rule" "ancillary_alb_ingress_http_global_protect_allowlist" {
#   for_each          = toset(local.all_ingress_ips)
#   security_group_id = aws_security_group.ancillary_alb_security_group.id
#   description       = "Access into alb over http (will redirect)"
#   from_port         = "80"
#   to_port           = "80"
#   ip_protocol       = "tcp"
#   cidr_ipv4         = each.key # Global Protect VPN
# }

resource "aws_vpc_security_group_egress_rule" "ancillary_alb_egress_private" {
  security_group_id = aws_security_group.ancillary_alb_security_group.id
  description       = "Access into alb over http (will redirect)"
  ip_protocol       = "-1"
  cidr_ipv4         = var.account_config.shared_vpc_cidr
}

# tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "delius_core_ancillary" {
  #checkov:skip=CKV_AWS_91 "ignore"
  #checkov:skip=CKV2_AWS_28 "ignore"
  #checkov:skip=CKV_AWS_150

  name               = "${var.env_name}-ancilliary-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ancillary_alb_security_group.id]
  subnets            = var.account_config.public_subnet_ids

  enable_deletion_protection = false
  drop_invalid_header_fields = true
}


resource "aws_lb_listener" "ancillary_https" {
  load_balancer_arn = aws_lb.delius_core_ancillary.id
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

resource "aws_lb_listener" "ancillary_http" {
  load_balancer_arn = aws_lb.delius_core_ancillary.id
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
