resource "aws_lb" "ebsapps_lb" {
  name               = lower(format("lb-%s-%s-ebsapp", local.application_name, local.environment))
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_ebsapps_lb.id]
  subnets            = data.aws_subnets.shared-public.ids

  enable_deletion_protection = false

  access_logs {
    bucket  = module.s3-bucket-logging.bucket.id
    prefix  = local.lb_log_prefix
    enabled = true
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-ebsapp", local.application_name, local.environment)) }
  )
}

/*
resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.ebsapps_lb.dns_name
    zone_id                = aws_lb.ebsapps_lb.zone_id
    evaluate_target_health = true
  }
}
*/

resource "aws_lb_listener" "ebsapps_listener" {
  depends_on = [
    aws_acm_certificate_validation.external-mp
  ]

  load_balancer_arn = aws_lb.ebsapps_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.external-mp[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ebsapp_tg.id
  }
}

resource "aws_lb_target_group" "ebsapp_tg" {
  name     = lower(format("tg-%s-%s-ebsapp", local.application_name, local.environment))
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.shared.id
  health_check {
    port     = 80
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group_attachment" "ebsapps" {
  count            = local.application_data.accounts[local.environment].accessgate_no_instances
  target_group_arn = aws_lb_target_group.ebsapp_tg.arn
  target_id        = element(aws_instance.ec2_ebsapps.*.id, count.index)
  port             = 80
}
