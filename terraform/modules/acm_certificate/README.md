Create an AWS ACM certificate with DNS validation against zones in current
account, core-vpc account or core-network-shared-services account. Ensure
the validation map contains entries for both the `domain_name` and all
entries within `subject_alternate_names`.

Example usage:

```
locals {
  acm_certificates = {

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
  for_each = local.acm_certificates

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
  cloudwatch_metric_alarms = {}
}
```
