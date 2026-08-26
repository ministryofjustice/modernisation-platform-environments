resource "aws_lb" "webgate_lb" {
  name               = lower(format("lb-%s-webgate", local.application_name))
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_webgate_lb.id]
  subnets            = data.aws_subnets.shared-private.ids

  drop_invalid_header_fields = true
  enable_deletion_protection = true

  access_logs {
    bucket  = module.s3-bucket-logging.bucket.id
    prefix  = local.lb_log_prefix_wgate_public
    enabled = true
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-webgate", local.application_name)) }
  )
}

resource "aws_lb_listener" "webgate_listener" {
  depends_on = [
    aws_acm_certificate_validation.external
  ]

  load_balancer_arn = aws_lb.webgate_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webgate_tg.id
  }
}

resource "aws_lb_target_group" "webgate_tg" {
  name     = lower(format("tg-%s-webgate", local.application_name))
  port     = 5401
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.shared.id
  health_check {
    port     = 5401
    protocol = "HTTP"
    matcher  = 302
    timeout  = 10
  }
}

resource "aws_lb_target_group_attachment" "webgate" {
  count            = local.application_data.accounts[local.environment].webgate_no_instances
  target_group_arn = aws_lb_target_group.webgate_tg.arn
  target_id        = element(aws_instance.ec2_webgate.*.id, count.index)
  port             = 5401
}
