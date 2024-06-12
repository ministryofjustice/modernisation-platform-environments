resource "aws_acm_certificate" "alb" {

  domain_name = local.application_data.accounts[local.environment].mp_domain_name
  subject_alternative_names = ["*.${data.aws_route53_zone.external.name}"]
  validation_method = "DNS"
  tags = local.tags

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route53_record" "external_lb_validation_core_network_services" {
  provider = aws.core-network-services
  for_each = {
    for key, value in local.external_lb_validation_records : key => value if value.zone.provider == "core-network-services"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type

  # NOTE: value.zone is null indicates the validation zone could not be found
  # Ensure route53_zones variable contains the given validation zone or
  # explicitly provide the zone details in the validation variable.
  zone_id = each.value.zone.zone_id

  depends_on = [
    aws_acm_certificate.alb
  ]
}

resource "aws_route53_record" "external_lb_validation_core_vpc" {
  provider = aws.core-vpc
  for_each = {
    for key, value in local.external_lb_validation_records : key => value if value.zone.provider == "core-vpc"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone.zone_id

  depends_on = [
    aws_acm_certificate.alb
  ]
}


resource "aws_acm_certificate_validation" "external_lb_certificate_validation" {
  # count           = (length(local.validation_records_external_lb) == 0 || local.external_validation_records_created) ? 1 : 0
  certificate_arn = aws_acm_certificate.alb.arn
  # validation_record_fqdns = [for record in aws_route53_record.external_lb_validation_core_network_services : record.fqdn]
  validation_record_fqdns = [
    for key, value in local.validation_records_external_lb : replace(value.name, "/\\.$/", "")
  ]
  depends_on = [
    aws_route53_record.external_lb_validation_core_network_services,
    aws_route53_record.external_lb_validation_core_vpc
    # aws_route53_record.external_lb_validation_self
  ]
}

