resource "aws_alb" "nextcloud" {
  name               = "nextcloud"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nextcloud_alb_sg.id]
  subnets            = var.account_config.ordered_private_subnet_ids
  tags               = var.tags
}

resource "aws_alb_listener" "nextcloud_https" {
  load_balancer_arn = aws_alb.nextcloud.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.nextcloud_external.arn

  default_action {
    type             = "forward"
    target_group_arn = module.nextcloud_service.target_group_arn
  }
}
