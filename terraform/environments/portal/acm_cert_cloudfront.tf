locals {
cloudfront_validation_records = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
      zone = lookup(
        local.route53_zones,
        dvo.domain_name,
        lookup(
          local.route53_zones,
          replace(dvo.domain_name, "/^[^.]*./", ""),
          lookup(
            local.route53_zones,
            replace(dvo.domain_name, "/^[^.]*.[^.]*./", ""),
            { provider = "external" }
      )))
    }
  }


validation_records_cloudfront = {
    for key, value in local.cloudfront_validation_records : key => {
      name   = value.name
      record = value.record
      type   = value.type
    } if value.zone.provider == "external"
  }

}


###### Cloudfront Cert
resource "aws_acm_certificate_validation" "cloudfront_certificate_validation" {
  count           = (length(local.validation_records_cloudfront) == 0 || local.external_validation_records_created) ? 1 : 0
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [
    for key, value in local.validation_records_cloudfront : replace(value.name, "/\\.$/", "")
  ]
  depends_on = [
    aws_route53_record.cloudfront_validation_core_network_services
    # aws_route53_record.cloudfront_validation_core_vpc,
    # aws_route53_record.cloudfront_validation_self
  ]
}

resource "aws_acm_certificate" "cloudfront" {
  # domain_name               = var.hosted_zone
  domain_name               = local.application_data.accounts[local.environment].acm_domain_name
  validation_method         = "DNS"
  provider                  = aws.us-east-1
  # subject_alternative_names = var.environment == "production" ? null : ["${var.application_name}.${var.business_unit}-${var.environment}.${var.hosted_zone}"]
  # subject_alternative_names = local.environment == "production" ? null : ["${local.application_name}.${local.networking[0].local.networking[0].business-unit}-${local.environment}.${local.portal_hosted_zone}"]
  # subject_alternative_names = local.environment == "production" ? null : [local.application_data.accounts[local.environment].fqdn]
  subject_alternative_names = local.environment == "production" ? null : [local.application_data.accounts[local.environment].acm_alt_domain_name]
  # tags                      = var.tags
  tags                      = local.tags
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route53_record" "cloudfront_validation_core_network_services" {
  provider = aws.core-network-services
  for_each = {
    for key, value in local.cloudfront_validation_records : key => value if value.zone.provider == "core-network-services"
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
    aws_acm_certificate.cloudfront
  ]
}
