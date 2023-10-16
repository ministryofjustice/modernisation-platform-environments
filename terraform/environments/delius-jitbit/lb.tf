# checkov:skip=CKV_AWS_226
# checkov:skip=CKV2_AWS_28

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

  ingress {
    protocol    = "tcp"
    description = "Allow ingress from white listed CIDRs"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [
      "81.134.202.29/32",  # MoJ Digital VPN
      "35.176.93.186/32",  # Global Protect VPN
      "217.33.148.210/32", # Digital studio
      "195.59.75.0/24",    # ARK internet (DOM1)
      "194.33.192.0/25",   # ARK internet (DOM1)
      "194.33.193.0/25",   # ARK internet (DOM1)
      "194.33.196.0/25",   # ARK internet (DOM1)
      "194.33.197.0/25",   # ARK internet (DOM1)

      # Route53 Healthcheck Access Cidrs
      # London Region not support yet, so metrics are not yet publised, can be enabled at later stage for Route53 endpoint monitor
      "15.177.0.0/18",     # GLOBAL Region
      "54.251.31.128/26",  # ap-southeast-1 Region
      "54.255.254.192/26", # ap-southeast-1 Region
      "176.34.159.192/26", # eu-west-1 Region
      "54.228.16.0/26",    # eu-west-1 Region
      "107.23.255.0/26",   # us-east-1 Region
      "54.243.31.192/26",  # us-east-1 Region
    ]

    ipv6_cidr_blocks = [
      # Route53 Healthcheck Access Cidrs IPv6
      "2406:da18:7ff:f800::/53",  # ap-southeast-1 Region
      "2406:da18:fff:f800::/53",  # ap-southeast-1 Region
      "2a05:d018:fff:f800::/53",  # eu-west-1 Region
      "2a05:d018:7ff:f800::/53",  # eu-west-1 Region
      "2600:1f18:7fff:f800::/53", # us-east-1 Region
      "2600:1f18:3fff:f800::/53", # us-east-1 Region
    ]
  }

  egress {
    protocol    = "tcp"
    description = "Allow egress to ECS instances"
    from_port   = local.app_port
    to_port     = local.app_port
    cidr_blocks = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-loadbalancer-security-group"
    }
  )
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.external.id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.external.arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = aws_lb_target_group.target_group_fargate.id
    type             = "forward"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_lb_target_group" "target_group_fargate" {
  # checkov:skip=CKV_AWS_261

  name                 = local.application_name
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
    interval            = "120"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}
