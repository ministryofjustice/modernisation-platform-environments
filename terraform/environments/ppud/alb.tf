
# PPUD ALB Configuration

resource "aws_lb" "PPUD-ALB" {
  name               = "PPUD-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.PPUD-ALB.id]
  subnets            = [data.aws_subnet.public_subnets_a.id,data.aws_subnet.public_subnets_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_lb_listener" "PPUD-Front-End" {
  load_balancer_arn = aws_lb.PPUD-ALB.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:eu-west-2:359821628648:certificate/688c6926-d3f6-471f-9a16-8b42f6b06a71"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.PPUD-Target-Group.arn
  }
}

resource "aws_lb_target_group" "PPUD-Target-Group" {
  name     = "PPUD"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = data.aws_vpc.shared.id
    stickiness {
    cookie_duration = 86400
    type            = "lb_cookie"
    enabled         = true
  }
}

resource "aws_lb_target_group_attachment" "PPUD-PORTAL" {
  target_group_arn = aws_lb_target_group.PPUD-Target-Group.arn
  target_id        = aws_instance.s609693lo6vw101.id
  port             = 443
}

resource "aws_lb_target_group_attachment" "PPUD-PORTAL-1" {
  target_group_arn = aws_lb_target_group.PPUD-Target-Group.arn
  target_id        = aws_instance.PPUDWEBSERVER2.id
  port             = 443
}

# WAM ALB Configuration

resource "aws_lb" "WAM-ALB" {
  name               = "WAM-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.WAM-ALB.id]
  subnets            = [data.aws_subnet.public_subnets_a.id,data.aws_subnet.public_subnets_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_lb_listener" "WAM-Front-End" {
  load_balancer_arn = aws_lb.WAM-ALB.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:eu-west-2:359821628648:certificate/688c6926-d3f6-471f-9a16-8b42f6b06a71"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.WAM-Target-Group.arn
  }
}

resource "aws_lb_target_group" "WAM-Target-Group" {
  name     = "WAM"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.shared.id
}

resource "aws_lb_target_group_attachment" "WAM-Portal" {
  target_group_arn = aws_lb_target_group.WAM-Target-Group.arn
  target_id        = aws_instance.s609693lo6vw105.id
  port             = 80
}