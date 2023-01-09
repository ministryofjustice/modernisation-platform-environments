locals {

  acm_certificates = {

    # define certs common to all environments
    "star.${local.application_name}.${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk" = {
      domain_name             = "modernisation-platform.service.justice.gov.uk"
      subject_alternate_names = ["*.${local.application_name}.${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
      validation = {
        "modernisation-platform.service.justice.gov.uk" = {
          account   = "core-network-services"
          zone_name = "modernisation-platform.service.justice.gov.uk."
        }
        "*.${local.application_name}.${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk" = {
          account   = "core-vpc"
          zone_name = "${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk."
        }
      }
      tags = {
        description = "wildcard cert for ${local.application_name} ${local.environment} modernisation platform domain"
      }
    }
  }
}

module "acm_certificate" {
  for_each = merge(local.acm_certificates, try(local.environment_config.acm_certificates, {}))

  source = "./modules/acm_certificate"

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  name                    = each.key
  domain_name             = each.value.domain_name
  subject_alternate_names = each.value.subject_alternate_names
  validation              = each.value.validation
  tags                    = merge(local.tags, lookup(each.value, "tags", {}))
}
