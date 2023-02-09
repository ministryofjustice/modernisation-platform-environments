resource "aws_lb" "ebsapps_lb" {
  name               = lower(format("lb-%s-%s-ebsapps", local.application_name, local.environment)) 
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_ebsapps_lb.id]
  subnets            = data.aws_subnets.shared-public.ids

  enable_deletion_protection = false
/*
  access_logs {
    bucket  = module.s3-bucket.arn #aws_s3_bucket.lb_logs.bucket
    prefix  = "ebsapps-lb"
    enabled = true
  }
*/
  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-ebsapps", local.application_name, local.environment)) }
  )
}

resource "aws_lb_listener" "ebsapps_listener" {
  depends_on = [
    aws_acm_certificate_validation.external
  ]

  load_balancer_arn = aws_lb.ebsapps_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ebsapp_tg.id
  }
}

resource "aws_lb_target_group" "ebsapp_tg" {
  name     = lower(format("tg-%s-%s-ebsapps", local.application_name, local.environment))
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.shared.id
  health_check {
    port     = 80
    protocol = "HTTP"
  }
}

resource "aws_acm_certificate" "external" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route53_record" "external_validation" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation : record.fqdn]
}
