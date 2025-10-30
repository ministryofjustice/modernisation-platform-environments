# checkov:skip=CKV_AWS_226
# checkov:skip=CKV2_AWS_28
locals {  
  target_groups = {
    blue  = aws_lb_target_group.target_group_fargate_blue.id
    green = aws_lb_target_group.target_group_fargate_green.id
  }

  active_target_group_arn = lookup(
    local.target_groups,
    data.aws_ssm_parameter.active_deployment_colour.value,
    null
  )
}

module "ip_addresses" {
  source = "../../modules/ip_addresses"
}

#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "external" {
  # checkov:skip=CKV_AWS_91
  # checkov:skip=CKV2_AWS_28

  name               = "${local.application_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_security_group.id]
  subnets            = data.aws_subnets.shared-public.ids

  enable_deletion_protection = true
  drop_invalid_header_fields = true

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_security_group" "load_balancer_security_group" {
  name_prefix = "${local.application_name}-loadbalancer-security-group"
  description = "controls access to lb"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-loadbalancer-security-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_ingress_rule" {
  for_each          = toset(local.internal_security_group_cidrs)
  description       = "Allow ingress from allow listed CIDRs"
  security_group_id = aws_security_group.load_balancer_security_group.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_ingress_rule_ipv6" {
  for_each          = toset(local.ipv6_cidr_blocks)
  description       = "Allow ingress from allow listed CIDRs"
  security_group_id = aws_security_group.load_balancer_security_group.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv6         = each.value
}

resource "aws_vpc_security_group_egress_rule" "load_balancer_egress_rule" {
  for_each          = toset([data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block])
  description       = "Allow egress to ECS instances"
  security_group_id = aws_security_group.load_balancer_security_group.id
  from_port         = local.app_port
  to_port           = local.app_port
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.external.id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.external.arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = local.active_target_group_arn
    type             = "forward"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

# resource "aws_lb_target_group" "target_group_fargate" {
#   # checkov:skip=CKV_AWS_261

#   name                 = local.application_name
#   port                 = local.app_port
#   protocol             = "HTTP"
#   vpc_id               = data.aws_vpc.shared.id
#   target_type          = "ip"
#   deregistration_delay = 30

#   stickiness {
#     type = "lb_cookie"
#   }

#   health_check {
#     path                = "/User/Login?ReturnUrl=%2f"
#     healthy_threshold   = "5"
#     interval            = "120"
#     protocol            = "HTTP"
#     unhealthy_threshold = "2"
#     matcher             = "200-499"
#     timeout             = "5"
#   }

#   tags = merge(
#     local.tags,
#     {
#       Name = local.application_name
#     }
#   )
# }

resource "aws_lb_target_group" "target_group_fargate_blue" {
  # checkov:skip=CKV_AWS_261

  name                 = "${local.application_name}-blue"
  port                 = local.app_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path                = "/User/Login?ReturnUrl=%2f"
    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-blue"
    }
  )
}

resource "aws_lb_target_group" "target_group_fargate_green" {
  # checkov:skip=CKV_AWS_261

  name                 = "${local.application_name}-green"
  port                 = local.app_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path                = "/User/Login?ReturnUrl=%2f"
    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-green"
    }
  )
}

resource "aws_lb_listener_rule" "listener_rule_blue" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 20

  action {
    target_group_arn = aws_lb_target_group.target_group_fargate_blue.arn
    type             = "forward"
  }

  condition {
    host_header {
      values = ["blue-${local.app_url}"]
    }
  }
}

resource "aws_lb_listener_rule" "listener_rule_green" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 30

  action {
    target_group_arn = aws_lb_target_group.target_group_fargate_green.arn
    type             = "forward"
  }

  condition {
    host_header {
      values = ["green-${local.app_url}"]
    }
  }
}
