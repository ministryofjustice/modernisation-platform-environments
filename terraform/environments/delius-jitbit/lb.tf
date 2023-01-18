#tfsec:ignore:aws-elbv2-alb-not-public
resource "aws_lb" "external" {
  name               = "${local.application_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_security_group.id]
  subnets            = data.aws_subnets.shared-public.ids

  enable_deletion_protection = true
  drop_invalid_header_fields = true
}

resource "aws_security_group" "load_balancer_security_group" {
  name_prefix = "${local.application_name}-loadbalancer-security-group"
  description = "controls access to lb"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    protocol    = "tcp"
    description = "Open the server port"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["81.134.202.29/32", ]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-loadbalancer-security-group"
    }
  )
}

#tfsec:ignore:aws-elbv2-http-not-used
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.external.id
  port              = 443
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group.id
    type             = "forward"
  }
}


resource "aws_lb_target_group" "target_group" {
  name                 = "${local.application_name}-tg-${local.environment}"
  port                 = local.app_data.accounts[local.environment].server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    # path                = "/"
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
      Name = "${local.application_name}-tg-${local.environment}"
    }
  )
}
