resource "aws_lb" "tribunals_lb_ftp" {
  count                      = var.is_ftp_app ? 1 : 0
  name                       = "${var.app_name}-ftp-lb"
  load_balancer_type         = "network"
  security_groups            = [aws_security_group.tribunals_lb_sc_sftp[0].id]
  subnets                    = var.subnets_shared_public_ids
  enable_deletion_protection = false
  internal                   = false
  depends_on                 = [aws_security_group.tribunals_lb_sc_sftp[0]]
}

resource "aws_lb_listener" "tribunals_lb_ftp" {
  count             = var.is_ftp_app ? 1 : 0
  load_balancer_arn = aws_lb.tribunals_lb_ftp[0].arn
  port              = 10022
  protocol          = var.application_data.lb_listener_protocol_3

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tribunals_target_group_sftp[0].arn
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

resource "aws_security_group" "tribunals_lb_sc_sftp" {
  count       = var.is_ftp_app ? 1 : 0
  name        = "${var.app_name}-load-balancer-sg-sftp"
  description = "${var.app_name} control access to the network load balancer"
  vpc_id      = var.vpc_shared_id

  ingress {
    description = "allow all traffic on HTTPS port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow all traffic on port 10022"
    from_port   = 10022
    to_port     = 10022
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_wafv2_web_acl_association" "web_acl_association_my_lb" {
  resource_arn = var.app_load_balancer.arn
  web_acl_arn  = var.waf_arn
}