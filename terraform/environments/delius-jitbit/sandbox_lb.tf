#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "external_sandbox" {
  # checkov:skip=CKV_AWS_91
  # checkov:skip=CKV2_AWS_28

  count = local.is-development ? 1 : 0

  name               = "${local.application_name}-lb-sandbox"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_security_group_sandbox[0].id]
  subnets            = data.aws_subnets.shared-public.ids

  drop_invalid_header_fields = true

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-sandbox"
    }
  )
}

resource "aws_security_group" "load_balancer_security_group_sandbox" {
  count = local.is-development ? 1 : 0

  name_prefix = "${local.application_name}-loadbalancer-security-group-sandbox"
  description = "controls access to lb"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    protocol    = "tcp"
    description = "Allow ingress from white listed CIDRs"
    from_port   = 443
    to_port     = 443
    cidr_blocks = flatten([
      "20.49.214.199/32", # Azure Landing Zone Egress
      "20.49.214.228/32", # Azure Landing Zone Egress
      "20.26.11.71/32",   # Azure Landing Zone Egress
      "20.26.11.108/32",  # Azure Landing Zone Egress
      # Route53 Healthcheck Access Cidrs
      # London Region not support yet, so metrics are not yet publised, can be enabled at later stage for Route53 endpoint monitor
      "15.177.0.0/18",     # GLOBAL Region
      "54.251.31.128/26",  # ap-southeast-1 Region
      "54.255.254.192/26", # ap-southeast-1 Region
      "176.34.159.192/26", # eu-west-1 Region
      "54.228.16.0/26",    # eu-west-1 Region
      "107.23.255.0/26",   # us-east-1 Region
      "54.243.31.192/26",  # us-east-1 Region
      local.internal_security_group_cidrs
    ])

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
      Name = "${local.application_name}-loadbalancer-security-group-sandbox"
    }
  )
}

resource "aws_lb_listener" "listener_sandbox" {
  count = local.is-development ? 1 : 0

  load_balancer_arn = aws_lb.external_sandbox[0].id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.external.arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = aws_lb_target_group.target_group_fargate_sandbox[0].id
    type             = "forward"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-sandbox"
    }
  )
}

resource "aws_lb_target_group" "target_group_fargate_sandbox" {
  # checkov:skip=CKV_AWS_261

  count = local.is-development ? 1 : 0

  name                 = "${local.application_name}-sandbox"
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
      Name = "${local.application_name}-sandbox"
    }
  )
}
