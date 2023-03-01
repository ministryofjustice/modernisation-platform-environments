# PPUD Internal ALB

resource "aws_lb" "PPUD-internal-ALB" {
  count              = local.is-development == false ? 1 : 0
  name               = local.application_data.accounts[local.environment].PPUD_Internal_ALB
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.PPUD-ALB.id]
  subnets            = [data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_lb_listener" "PPUD-Front-End" {
  count              = local.is-development == false ? 1 : 0
  load_balancer_arn = aws_lb.PPUD-internal-ALB[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.internaltest_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.PPUD-internal-Target-Group.arn
  }
}

resource "aws_lb_target_group" "PPUD-internal-Target-Group" {
  name     = "PPUD"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = data.aws_vpc.shared.id
  stickiness {
    cookie_duration = 86400
    type            = "lb_cookie"
    enabled         = true
  }

  health_check {
    enabled             = true
    path                = "/"
    interval            = 30
    protocol            = "HTTPS"
    port                = 443
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "302"
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }

}

/*
resource "aws_lb_target_group_attachment" "PPUD-PORTAL" {
  target_group_arn = aws_lb_target_group.PPUD-Target-Group.arn
  target_id        = aws_instance.s609693lo6vw101[0].id
  port             = 443
}
*/

resource "aws_lb_target_group_attachment" "PPUD-PORTAL-internal" {
  count              = local.is-development == false ? 1 : 0
  target_group_arn = aws_lb_target_group.PPUD-internal-Target-Group.arn
# target_id        = aws_instance.PPUDWEBSERVER2[0].id
  target_id        = local.application_data.accounts[local.environment].alb_intances_ppud
  port             = 443
}


/*
resource "aws_lb_target_group_attachment" "target_group_attachment_1" {
  count            = length(var.instance_ids_ppud_internal_alb[terraform.workspace])
  target_group_arn = aws_lb_target_group.PPUD-Target-Group.arn
  target_id        = var.instance_ids_ppud_internal_alb[terraform.workspace][count.index]
 }
 */