resource "aws_security_group" "chaps_lb_sc" {
  name        = "load balancer security group"
  description = "control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow access on HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow access on HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Open all outbound ports"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "chaps_lb" {
  name                       = "chaps-load-balancer"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.chaps_lb_sc.id]
  subnets                    = data.aws_subnets.shared-public.ids
}

resource "aws_lb_target_group" "chaps_target_group" {
  name                 = "chaps-target-group"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    port                = "80"
    unhealthy_threshold = "5"
    matcher             = "200-499"
    timeout             = "10"
  }
}

# TODO: delete
resource "aws_lb_target_group" "chaps_tg" {
  name                 = "chaps-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    port                = "80"
    unhealthy_threshold = "5"
    matcher             = "200-499"
    timeout             = "10"
  }
}

resource "aws_lb_listener" "listener" {
  #checkov:skip=CKV_AWS_103
  load_balancer_arn = aws_lb.chaps_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.chaps_target_group.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "https_listener" {
  #checkov:skip=CKV_AWS_103
  depends_on = [aws_acm_certificate_validation.external]

  load_balancer_arn = aws_lb.chaps_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    target_group_arn = aws_lb_target_group.chaps_target_group
    type             = "forward"
  }
}
