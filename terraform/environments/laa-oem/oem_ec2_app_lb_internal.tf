resource "aws_lb" "oem_app_internal" {
  name               = "lb-${local.application_name}-app-internal"
  load_balancer_type = "application"
  internal           = true
  security_groups    = [aws_security_group.load_balancer_internal.id]
  subnets            = data.aws_subnets.shared-private.ids

  tags = local.tags
}

resource "aws_lb_listener" "oem_app_internal" {
  load_balancer_arn = aws_lb.oem_app_internal.id
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate.laa_cert.arn

  default_action {
    target_group_arn = aws_lb_target_group.oem_app_internal.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "oem_app_3872_internal" {
  load_balancer_arn = aws_lb.oem_app_internal.id
  port              = 3872
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate.laa_cert.arn

  default_action {
    target_group_arn = aws_lb_target_group.oem_app_3872_internal.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "oem_app_4903_internal" {
  load_balancer_arn = aws_lb.oem_app_internal.id
  port              = 4903
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate.laa_cert.arn

  default_action {
    target_group_arn = aws_lb_target_group.oem_app_4903_internal.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "oem_app_7102_internal" {
  load_balancer_arn = aws_lb.oem_app_internal.id
  port              = 7102
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate.laa_cert.arn

  default_action {
    target_group_arn = aws_lb_target_group.oem_app_7102_internal.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "oem_app_7803_internal" {
  load_balancer_arn = aws_lb.oem_app_internal.id
  port              = 7803
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate.laa_cert.arn

  default_action {
    target_group_arn = aws_lb_target_group.oem_app_7803_internal.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "oem_app_internal" {
  name        = "tg-${local.application_name}-app-8000-internal"
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

resource "aws_lb_target_group" "oem_app_3872_internal" {
  name        = "tg-${local.application_name}-app-3872-internal"
  port        = 3872
  protocol    = "HTTPS"
  vpc_id      = data.aws_vpc.shared.id
  target_type = "instance"

  health_check {
    path                = "/emd/main"
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

resource "aws_lb_target_group" "oem_app_4903_internal" {
  name        = "tg-${local.application_name}-app-4903-internal"
  port        = 4903
  protocol    = "HTTPS"
  vpc_id      = data.aws_vpc.shared.id
  target_type = "instance"

  health_check {
    path                = "/empbs/upload"
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

resource "aws_lb_target_group" "oem_app_7102_internal" {
  name        = "tg-${local.application_name}-app-7102-internal"
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

resource "aws_lb_target_group" "oem_app_7803_internal" {
  name        = "tg-${local.application_name}-app-7803-internal"
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

resource "aws_lb_target_group_attachment" "oem_app_internal" {
  target_group_arn = aws_lb_target_group.oem_app_internal.arn
  target_id        = aws_instance.oem_app.id
  port             = 8000
}

resource "aws_lb_target_group_attachment" "oem_app_3872_internal" {
  target_group_arn = aws_lb_target_group.oem_app_3872_internal.arn
  target_id        = aws_instance.oem_app.id
  port             = 3872
}

resource "aws_lb_target_group_attachment" "oem_app_4903_internal" {
  target_group_arn = aws_lb_target_group.oem_app_4903_internal.arn
  target_id        = aws_instance.oem_app.id
  port             = 4903
}

resource "aws_lb_target_group_attachment" "oem_app_7102_internal" {
  target_group_arn = aws_lb_target_group.oem_app_7102_internal.arn
  target_id        = aws_instance.oem_app.id
  port             = 7102
}

resource "aws_lb_target_group_attachment" "oem_app_7803_internal" {
  target_group_arn = aws_lb_target_group.oem_app_7803_internal.arn
  target_id        = aws_instance.oem_app.id
  port             = 7803
}

resource "aws_security_group" "load_balancer_internal" {
  name_prefix = "${local.application_name}-lb-sg-int-"
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
    from_port   = 3872
    to_port     = 3872
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_lz_workspaces]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 3872
    to_port     = 3872
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 4903
    to_port     = 4903
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_lz_workspaces]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 4903
    to_port     = 4903
    cidr_blocks = ["0.0.0.0/0"]
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

  ingress {
    protocol    = "tcp"
    from_port   = 7803
    to_port     = 7803
    cidr_blocks = ["0.0.0.0/0"]
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
