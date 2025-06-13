#--NEED TO CONFIGURE ACCESS LOGS!!! - AW

#--Admin
resource "aws_lb" "admin" {
  name               = "${local.application_data.accounts[local.environment].app_name}-admin-lb"
  load_balancer_type = "network"
  internal           = true
  subnets            = data.aws_subnets.shared-private.ids
  security_groups    = [aws_security_group.alb_admin.id]
}

resource "aws_lb_target_group" "admin" {
  name                 = "${local.application_data.accounts[local.environment].app_name}-admin-target-group"
  port                 = local.application_data.accounts[local.environment].admin_server_port
  protocol             = "TCP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "TCP"
    unhealthy_threshold = "3"
  }
}

resource "aws_lb_listener" "admin80" {
  load_balancer_arn = aws_lb.admin.id
  port              = 80 #--Don't know why HTTP is being listened, is this a redirect? Why? - Revist. AW
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.admin.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "admin443" {
  load_balancer_arn = aws_lb.admin.id
  port              = 443
  protocol          = "TCP"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.soa.arn
  default_action {
    target_group_arn = aws_lb_target_group.admin.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "admin_server_port" {
  load_balancer_arn = aws_lb.admin.id
  port              = local.application_data.accounts[local.environment].admin_server_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.admin.id
    type             = "forward"
  }
}

#--Managed
resource "aws_lb" "managed" {
  name               = "${local.application_data.accounts[local.environment].app_name}-managed-api-lb"
  load_balancer_type = "network"
  internal           = true
  subnets            = data.aws_subnets.shared-private.ids
  security_groups    = [aws_security_group.alb_managed.id]
}

resource "aws_lb_target_group" "managed" {
  name        = "${local.application_data.accounts[local.environment].app_name}-managed-target-group"
  port        = local.application_data.accounts[local.environment].managed_server_port
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.shared.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "TCP"
    unhealthy_threshold = "3"
  }
}

resource "aws_lb_listener" "managed80" {
  load_balancer_arn = aws_lb.managed.id
  port              = 80 #--Don't know why HTTP is being listened, is this a redirect? Why? - Revist. AW
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.managed.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "managed443" {
  load_balancer_arn = aws_lb.managed.id
  port              = 443
  protocol          = "TCP"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.soa.arn
  default_action {
    target_group_arn = aws_lb_target_group.managed.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "managed_server_port" {
  load_balancer_arn = aws_lb.managed.id
  port              = local.application_data.accounts[local.environment].managed_server_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.managed.id
    type             = "forward"
  }
}