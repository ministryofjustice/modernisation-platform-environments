resource "aws_security_group" "chaps_lb_sc" {
  name        = "load balancer security group"
  description = "control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow access on HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound traffic for port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound traffic for port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "old" {
  name                       = "cdpt-chaps-loadbalancer"
  enable_deletion_protection = false
}

resource "aws_lb" "chaps_lb" {
  name                       = "chaps-load-balancer"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.chaps_lb_sc.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  internal                   = false
  depends_on                 = [aws_security_group.chaps_lb_sc]
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
    matcher             = "200-302"
    timeout             = "10"
  }

}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.chaps_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.chaps_target_group.id
    type             = "forward"
  }
}

# resource "aws_lb_listener" "chaps_lb" {
#   depends_on = [
#     aws_acm_certificate.external
#   ]
#   certificate_arn   = aws_acm_certificate.external.arn
#   load_balancer_arn = aws_lb.chaps_lb.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.chaps_target_group.arn
#   }
# }
