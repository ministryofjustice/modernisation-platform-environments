resource "aws_security_group" "tribunals_lb_sc" {
  name        = "${var.app_name}-load-balancer-sg"
  description = "${var.app_name} control access to the load balancer"
  vpc_id      = var.vpc_shared_id

  ingress {
    description = "allow all traffic on HTTPS port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow all traffic on HTTP port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound traffic from the load balancer - needed due to dynamic port mapping on ec2 instance"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//noinspection HILUnresolvedReference
resource "aws_lb" "tribunals_lb" {
  name                       = "${var.app_name}-lb"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.tribunals_lb_sc.id]
  subnets                    = var.subnets_shared_public_ids
  enable_deletion_protection = false
  internal                   = false
  depends_on                 = [aws_security_group.tribunals_lb_sc]
}

resource "aws_lb" "tribunals_lb_ftp" {
  count                      = var.is_ftp_app ? 1 : 0
  name                       = "${var.app_name}-ftp-lb"
  load_balancer_type         = "network"
  security_groups            = [aws_security_group.tribunals_lb_sc.id]
  subnets                    = var.subnets_shared_public_ids
  enable_deletion_protection = false
  internal                   = false
  depends_on                 = [aws_security_group.tribunals_lb_sc]
}

resource "aws_lb_target_group" "tribunals_target_group" {
  name                 = "${var.app_name}-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_shared_id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    healthy_threshold   = "3"
    interval            = "15"
    protocol            = "HTTP"
    unhealthy_threshold = "3"
    matcher             = "200-499"
    timeout             = "10"
  }

}

resource "aws_lb_target_group" "tribunals_target_group_sftp" {
  count                = var.is_ftp_app ? 1 : 0
  name                 = "${var.app_name}-sftp-tg"
  port                 = 22
  protocol             = "TCP"
  vpc_id               = var.vpc_shared_id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = "3"
    interval            = "15"
    protocol            = "TCP"
    unhealthy_threshold = "3"
    timeout             = "10"
  }
}

resource "aws_lb_listener" "tribunals_lb" {
  depends_on = [
    var.aws_acm_certificate_external
  ]
  certificate_arn   = var.aws_acm_certificate_external.arn
  load_balancer_arn = aws_lb.tribunals_lb.arn
  port              = var.application_data.server_port_2
  protocol          = var.application_data.lb_listener_protocol_2
  ssl_policy        = var.application_data.lb_listener_protocol_2 == "HTTP" ? "" : "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tribunals_target_group.arn
  }
}

resource "aws_lb_listener" "tribunals_lb_ftp" {
  count             = var.is_ftp_app ? 1 : 0
  load_balancer_arn = aws_lb.tribunals_lb_ftp[0].arn
  port              = var.application_data.server_port_3
  protocol          = var.application_data.lb_listener_protocol_3

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tribunals_target_group_sftp[0].arn
  }
}

resource "aws_lb_listener" "tribunals_lb_health" {
  load_balancer_arn = aws_lb.tribunals_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tribunals_target_group.arn
  }
}