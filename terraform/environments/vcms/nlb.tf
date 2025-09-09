data "aws_lb" "service_nlb" {
  name = "vcms-${local.environment}-service-nlb"
}

resource "aws_lb_listener" "tls" {
  load_balancer_arn = module.vcms_service.nlb_arn
  port              = 443
  protocol          = "TLS"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    type             = "forward"
    target_group_arn = module.vcms_service.nlb_target_group_arn_map["80"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-tls-listener"
    }
  )
}