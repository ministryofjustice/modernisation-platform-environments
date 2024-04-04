## Certificates
#   *.laa-development.modernisation-platform.service.justice.gov.uk
#   *.laa-test.modernisation-platform.service.justice.gov.uk
#   *.laa-preproduction.modernisation-platform.service.justice.gov.uk

resource "aws_acm_certificate" "external" {
  count = local.is-production ? 0 : 1

  validation_method = "DNS"
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  subject_alternative_names = [
    "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  ]

  tags = merge(local.tags,
    { Environment = local.environment }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# *.service.justice.gov.uk
resource "aws_acm_certificate" "external-service" {
  count = local.is-production ? 1 : 0

  validation_method = "DNS"
  domain_name       = "ccms-ebs.service.justice.gov.uk"
  subject_alternative_names = [
    "*.ccms-ebs.service.justice.gov.uk"
  ]

  tags = merge(local.tags,
    { Environment = local.environment }
  )

  lifecycle {
    create_before_destroy = true
  }
}

## Validation

resource "aws_route53_record" "external_validation_core_network" {
  count = local.is-production ? 0 : 1

  depends_on = [
    aws_instance.ec2_oracle_ebs,
    aws_instance.ec2_ebsapps,
    aws_instance.ec2_webgate,
    aws_instance.ec2_accessgate
  ]

  provider = aws.core-network-services

  allow_overwrite = true
  name            = lookup(aws_acm_certificate.external[0].domain_validation_options, "domain_name", "modernisation-platform.service.justice.gov.uk").resource_record_name
  records         = lookup(aws_acm_certificate.external[0].domain_validation_options, "domain_name", "modernisation-platform.service.justice.gov.uk").resource_record_value
  type            = lookup(aws_acm_certificate.external[0].domain_validation_options, "domain_name", "modernisation-platform.service.justice.gov.uk").resource_record_type
  # name            = aws_acm_certificate.external[0].domain_validation_options[0].resource_record_name
  # records         = aws_acm_certificate.external[0].domain_validation_options[0].resource_record_value
  ttl = 60
  #  type            = aws_acm_certificate.external[0].domain_validation_options[0].resource_record_type
  zone_id = local.cert_zone_id
}


resource "aws_route53_record" "external_validation_core_vpc" {
  count = local.is-production ? 0 : 1

  depends_on = [
    aws_instance.ec2_oracle_ebs,
    aws_instance.ec2_ebsapps,
    aws_instance.ec2_webgate,
    aws_instance.ec2_accessgate
  ]

  provider = aws.core-vpc

  name            = lookup(aws_acm_certificate.external[0].domain_validation_options, "domain_name", "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk").resource_record_name
  records         = lookup(aws_acm_certificate.external[0].domain_validation_options, "domain_name", "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk").resource_record_value
  type            = lookup(aws_acm_certificate.external[0].domain_validation_options, "domain_name", "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk").resource_record_type

#  name    = aws_acm_certificate.external[0].domain_validation_options[1].resource_record_name
#  records = aws_acm_certificate.external[0].domain_validation_options[1].resource_record_value
  ttl     = 60
#  type    = aws_acm_certificate.external[0].domain_validation_options[1].resource_record_type
  zone_id = local.cert_zone_id
}

# resource "aws_route53_record" "external_validation" {

#   depends_on = [
#     aws_instance.ec2_oracle_ebs,
#     aws_instance.ec2_ebsapps,
#     aws_instance.ec2_webgate,
#     aws_instance.ec2_accessgate
#   ]

#   provider = aws.core-network-services

#   if (length(aws_acm_certificate.external-service[0].domain_validation_options) >= 1 &&
#       aws_acm_certificate.external-service[0].domain_validation_options[0].domain_name == "domain1.example.com") {
#     name   = aws_acm_certificate.external-service[0].domain_validation_options[0].resource_record_name
#     records = aws_acm_certificate.external-service[0].domain_validation_options[0].resource_record_value
#     type    = aws_acm_certificate.external-service[0].domain_validation_options[0].resource_record_type
#   } else if (length(aws_acm_certificate.external-service[0].domain_validation_options) >= 2 &&
#             aws_acm_certificate.external-service[0].domain_validation_options[1].domain_name == "domain2.example.com") {
#     name   = aws_acm_certificate.external-service[0].domain_validation_options[1].resource_record_name
#     records = aws_acm_certificate.external-service[0].domain_validation_options[1].resource_record_value
#     type    = aws_acm_certificate.external-service[0].domain_validation_options[1].resource_record_type
#   }
#   allow_overwrite = true
#   # name            = each.value.name
#   # records         = [each.value.record]
#   ttl             = 60
#   # type            = each.value.type
#   zone_id         = local.cert_zone_id
# }

resource "aws_acm_certificate_validation" "external" {
  count = local.is-production ? 1 : 1

  depends_on = [
    aws_route53_record.external_validation
  ]

  certificate_arn         = local.cert_arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}
