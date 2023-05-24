# Certificate

locals {

  domain_types = { for dvo in aws_acm_certificate.ebs_vision_db_lb_cert.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  domain_name_main   = [for k, v in local.domain_types : v.name if k == "modernisation-platform.service.justice.gov.uk"]
  domain_name_sub    = [for k, v in local.domain_types : v.name if k != "modernisation-platform.service.justice.gov.uk"]
  domain_record_main = [for k, v in local.domain_types : v.record if k == "modernisation-platform.service.justice.gov.uk"]
  domain_record_sub  = [for k, v in local.domain_types : v.record if k != "modernisation-platform.service.justice.gov.uk"]
  domain_type_main   = [for k, v in local.domain_types : v.type if k == "modernisation-platform.service.justice.gov.uk"]
  domain_type_sub    = [for k, v in local.domain_types : v.type if k != "modernisation-platform.service.justice.gov.uk"]
}

resource "aws_acm_certificate" "ebs_vision_db_lb_cert" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"
  subject_alternative_names = ["*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk",
  ]

  tags = merge(local.tags,
    { Environment = local.environment }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Certificate Validation
resource "aws_acm_certificate_validation" "ebs_vision_db_lb_cert_validation" {
  certificate_arn         = aws_acm_certificate.ebs_vision_db_lb_cert.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]

  timeouts {
    create = "10m"
  }
}

# Route 53 Certificate Validation Record
resource "aws_route53_record" "ebs_vision_db_cert_validation" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "ebs_vision_db_cert_validation_subdomain" {
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}




# Route53 DNS data
#data "aws_route53_zone" "external" {
#  provider = aws.core-vpc
#
#  name         = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk."
#  private_zone = false
#}
#
#data "aws_route53_zone" "inner" {
#  provider = aws.core-vpc
#
#  name         = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.internal."
#  private_zone = true
#}
#
#data "aws_route53_zone" "network-services" {
#  provider = aws.core-network-services
#
#  name         = "modernisation-platform.service.justice.gov.uk."
#  private_zone = false
#}





resource "aws_lb_listener" "ebs_vision_db_listener_https" {
  depends_on = [
    /*aws_acm_certificate.ebs_vision_db_lb_cert,
    aws_route53_record.ebs_vision_db_cert_validation,
    aws_route53_record.ebs_vision_db_cert_validation_subdomain,*/
    aws_acm_certificate_validation.ebs_vision_db_lb_cert_validation
  ]

  load_balancer_arn = aws_lb.ebs_vision_db_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.ebs_vision_db_lb_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ebs_vision_db_tg_http.arn
  }
}

