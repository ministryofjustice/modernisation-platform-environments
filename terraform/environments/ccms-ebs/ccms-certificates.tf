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
  depends_on = [
    aws_instance.ec2_oracle_ebs,
    aws_instance.ec2_ebsapps,
    aws_instance.ec2_webgate,
    aws_instance.ec2_accessgate
  ]

  provider = aws.core-network-services

  for_each = {
    for dvo in local.cert_opts : dvo.domain_name == "modernisation-platform.service.justice.gov.uk" => {
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
  zone_id         = local.cert_zone_id
}


resource "aws_route53_record" "external_validation_core_vpc" {
  depends_on = [
    aws_instance.ec2_oracle_ebs,
    aws_instance.ec2_ebsapps,
    aws_instance.ec2_webgate,
    aws_instance.ec2_accessgate
  ]

  provider = aws.core-vpc

  for_each = {
    for dvo in local.cert_opts : dvo.domain_name != "modernisation-platform.service.justice.gov.uk" => {
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
  zone_id         = local.cert_zone_id
}

# resource "aws_route53_record" "external_validation" {
#   depends_on = [
#     aws_instance.ec2_oracle_ebs,
#     aws_instance.ec2_ebsapps,
#     aws_instance.ec2_webgate,
#     aws_instance.ec2_accessgate
#   ]

#   provider = aws.core-network-services

#   for_each = {
#     for dvo in local.cert_opts : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = local.cert_zone_id
# }

resource "aws_acm_certificate_validation" "external_nonprod" {
  count = local.is-production ? 0 : 1

  depends_on = [
    aws_route53_record.external_validation_core_network,
    aws_route53_record.external_validation_core_vpc
  ]

  certificate_arn = local.cert_arn
  validation_record_fqdns = concat(
    [for record in aws_route53_record.external_validation_core_network : record.fqdn],
    [for record in aws_route53_record.external_validation_core_vpc : record.fqdn]
  )

  timeouts {
    create = "10m"
  }
}

resource "aws_acm_certificate_validation" "external" {
  count = local.is-production ? 1 : 0

  depends_on = [
    aws_route53_record.external_validation_core_network
  ]

  certificate_arn         = local.cert_arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation_core_network : record.fqdn]

  timeouts {
    create = "10m"
  }
}
