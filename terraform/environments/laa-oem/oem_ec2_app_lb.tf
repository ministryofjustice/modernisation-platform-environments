resource "aws_lb" "oem_app" {
  name               = "lb-${local.application_name}-app"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.load_balancer_security_group.id]
  subnets            = data.aws_subnets.shared-public.ids

  tags = local.tags
}

resource "aws_lb_target_group" "oem_app" {
  name        = "tg-${local.application_name}-app-8000"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.shared.id
  target_type = "instance"

  health_check {
    path                = "/OA_HTML/AppsLocalLogin.jsp"
    healthy_threshold   = "5"
    interval            = "60"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "302"
    timeout             = "5"
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "oem_app_7102" {
  name        = "tg-${local.application_name}-app-7102"
  port        = 7102
  protocol    = "HTTPS"
  vpc_id      = data.aws_vpc.shared.id
  target_type = "instance"

  health_check {
    path                = "/console"
    healthy_threshold   = "5"
    interval            = "60"
    protocol            = "HTTPS"
    unhealthy_threshold = "2"
    matcher             = "200"
    timeout             = "5"
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "oem_app_7803" {
  name        = "tg-${local.application_name}-app-7803"
  port        = 7803
  protocol    = "HTTPS"
  vpc_id      = data.aws_vpc.shared.id
  target_type = "instance"

  health_check {
    path                = "/em"
    healthy_threshold   = "5"
    interval            = "60"
    protocol            = "HTTPS"
    unhealthy_threshold = "2"
    matcher             = "200"
    timeout             = "5"
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "oem_app" {
  target_group_arn = aws_lb_target_group.oem_app.arn
  target_id        = aws_instance.oem_app.id
  port             = 8000
}

resource "aws_lb_target_group_attachment" "oem_app_7102" {
  target_group_arn = aws_lb_target_group.oem_app_7102.arn
  target_id        = aws_instance.oem_app.id
  port             = 7102
}

resource "aws_lb_target_group_attachment" "oem_app_7803" {
  target_group_arn = aws_lb_target_group.oem_app_7803.arn
  target_id        = aws_instance.oem_app.id
  port             = 7803
}

resource "aws_lb_listener" "oem_app" {
  load_balancer_arn = aws_lb.oem_app.id
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate.external-mp[0].arn

  default_action {
    target_group_arn = aws_lb_target_group.oem_app.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "oem_app_7102" {
  load_balancer_arn = aws_lb.oem_app.id
  port              = 7102
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate.external-mp[0].arn

  default_action {
    target_group_arn = aws_lb_target_group.oem_app_7102.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "oem_app_7803" {
  load_balancer_arn = aws_lb.oem_app.id
  port              = 7803
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate.external-mp[0].arn

  default_action {
    target_group_arn = aws_lb_target_group.oem_app_7803.id
    type             = "forward"
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  name_prefix = "${local.application_name}-load-balancer-sg-"
  description = "Access to the EBS App server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(tomap(
    { "Name" = "${local.application_name}-app-lb-sg" }
  ), local.tags)

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_lz_workspaces]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 7102
    to_port     = 7102
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_lz_workspaces]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 7803
    to_port     = 7803
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_lz_workspaces]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}
