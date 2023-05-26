locals {

  core_network_services_domains = {
    for domain, value in var.validation : domain => value if value.account == "core-network-services"
  }
  core_vpc_domains = {
    for domain, value in var.validation : domain => value if value.account == "core-vpc"
  }
  self_domains = {
    for domain, value in var.validation : domain => value if value.account == "self"
  }

  route53_zones = merge(var.route53_zones, {
    for key, value in data.aws_route53_zone.core_network_services : key => merge(value, {
      provider = "core-network-services"
    })
    }, {
    for key, value in data.aws_route53_zone.core_vpc : key => merge(value, {
      provider = "core-vpc"
    })
    }, {
    for key, value in data.aws_route53_zone.self : key => merge(value, {
      provider = "self"
    })
  })

  # Find the validation route53 zone objects.  The lookups will strip the first
  # element of the domain_name until the zone is found (for 2 levels), e.g.
  #   nomis.hmpps-test.modernisation-platform.service.justice.gov.uk
  # is found in the hmpps-test.modernisation-platform.service.justice.gov.uk zone
  #
  validation_records = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
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

  validation_records_external = {
    for key, value in local.validation_records : key => {
      name   = value.name
      record = value.record
      type   = value.type
    } if value.zone.provider == "external"
  }
}
