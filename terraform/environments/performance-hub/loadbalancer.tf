#------------------------------------------------------------------------------
# Load Balancer
#------------------------------------------------------------------------------
#tfsec:ignore:AWS005 tfsec:ignore:AWS083
resource "aws_lb" "external" {
  #checkov:skip=CKV_AWS_91
  #checkov:skip=CKV_AWS_131
  #checkov:skip=CKV2_AWS_20
  #checkov:skip=CKV2_AWS_28
  name                       = "${local.application_name}-loadbalancer"
  load_balancer_type         = "application"
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = true
  # allow 60*4 seconds before 504 gateway timeout for long-running DB operations
  idle_timeout = 240

  security_groups = [aws_security_group.load_balancer_security_group.id]

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-external-loadbalancer"
    }
  )
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

#tfsec:ignore:AWS004
resource "aws_lb_listener" "listener" {
  #checkov:skip=CKV_AWS_2
  #checkov:skip=CKV_AWS_103
  load_balancer_arn = aws_lb.external.id
  port              = local.app_data.accounts[local.environment].server_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "https_listener" {
  #checkov:skip=CKV_AWS_103
  depends_on = [aws_acm_certificate_validation.external]

  load_balancer_arn = aws_lb.external.id
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = format("arn:aws:acm:eu-west-2:%s:certificate/%s", data.aws_caller_identity.current.account_id, local.app_data.accounts[local.environment].cert_arn)

  default_action {
    target_group_arn = aws_lb_target_group.target_group.id
    type             = "forward"
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  name_prefix = "${local.application_name}-loadbalancer-security-group"
  description = "controls access to lb"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    protocol    = "tcp"
    description = "Open the server port"
    from_port   = local.app_data.accounts[local.environment].server_port
    to_port     = local.app_data.accounts[local.environment].server_port
    #tfsec:ignore:AWS008
    cidr_blocks = ["0.0.0.0/0", ]
  }

  ingress {
    protocol    = "tcp"
    description = "Open the SSL port"
    from_port   = 443
    to_port     = 443
    #tfsec:ignore:AWS008
    cidr_blocks = ["0.0.0.0/0", ]
  }

  egress {
    protocol    = "-1"
    description = "Open all outbound ports"
    from_port   = 0
    to_port     = 0
    #tfsec:ignore:AWS009
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-loadbalancer-security-group"
    }
  )
}
