resource "aws_lb" "ebsapps_lb" {
  count              = local.is-production ? 1 : 0
  name               = lower(format("lb-%s-%s-ebsapp", local.application_name, local.environment))
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_ebsapps_lb.id]
  subnets            = data.aws_subnets.shared-public.ids

  drop_invalid_header_fields = true
  enable_deletion_protection = false

  access_logs {
    bucket  = module.s3-bucket-logging.bucket.id
    prefix  = local.lb_log_prefix_ebsapp
    enabled = true
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-ebsapp", local.application_name, local.environment)) }
  )
}

resource "aws_lb_listener" "ebsapps_listener" {
  count             = local.is-production ? 1 : 0

  load_balancer_arn = aws_lb.ebsapps_lb[count.index].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.gandi_cert[0].arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This service has moved to the new address. Please update your bookmark to ${local.application_data.accounts[local.environment].ebs_new_url}"
      status_code  = "410"
    }
  }
}

resource "aws_lb_target_group" "ebsapp_tg" {
  count    = local.is-production ? 1 : 0
  name     = lower(format("tg-%s-%s-ebsapp", local.application_name, local.environment))
  port     = local.application_data.accounts[local.environment].tg_apps_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.shared.id
  health_check {
    port     = local.application_data.accounts[local.environment].tg_apps_port
    protocol = "HTTP"
  }

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 3600
  }
}

resource "aws_lb_target_group_attachment" "ebsapps" {
  count            = local.is-production ? local.application_data.accounts[local.environment].ebsapps_no_instances : 0
  target_group_arn = aws_lb_target_group.ebsapp_tg[0].arn
  target_id        = element(aws_instance.ec2_ebsapps.*.id, count.index)
  port             = local.application_data.accounts[local.environment].tg_apps_port
}

resource "aws_wafv2_web_acl_association" "ebs_waf_association" {
  count        = local.is-production ? 1 : 0
  resource_arn = aws_lb.ebsapps_lb[0].arn
  web_acl_arn  = aws_wafv2_web_acl.ebs_web_acl.arn
}
