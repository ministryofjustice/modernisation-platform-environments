Create an AWS ACM certificate with DNS validation against zones in current
account, core-vpc account or core-network-shared-services account. Ensure
the validation map contains entries for both the `domain_name` and all
entries within `subject_alternate_names`.

Example usage:

```
locals {
  acm_certificates = {
    common = {

      "star.${local.application_name}.${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk" = {
        domain_name             = "modernisation-platform.service.justice.gov.uk"
        subject_alternate_names = ["*.${local.application_name}.${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
        tags = {
          description = "wildcard cert for ${local.application_name} ${local.environment} modernisation platform domain"
        }
      }
    }
    cloudwatch_metric_alarms_acm = {
      name-of-alarm-here = {
        See alarm examples in nomis/locals-acm-certificates.tf
        NOTE: This can be an empty map if no alarms are required
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
  route53_zones           = module.environment.route53_zones  # a map of all created zones for use in validation
  validation              = each.value.validation             # or use this to explicitly define validation
  tags                    = merge(local.tags, lookup(each.value, "tags", {}))
  cloudwatch_metric_alarms = {
    for key, value in local.acm_certificates.cloudwatch_metric_alarms_acm :
    key => merge(value, {
      alarm_actions = [lookup(local.environment_config, "sns_topic", aws_sns_topic.nomis_nonprod_alarms.arn)]
    })
  }
}
```

Validation records are created in the relevant zone. The zone is looked up from the `route53_zones`
variable using the domain name as the key to the map. Alternatively, use the `validation` option
to explicitly define the mapping between `domain_name` and `zone`, e.g.

```
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
```

With the alarm settings - don't forget to set your own aws_sns_topic values.

If you want to use a channel specifically for say, <environment>-producation then you can do that by adding the following to that environment's locals-<environment>.tf file: `sns_topic = aws_sns_topic.<sns_topic>.arn`
