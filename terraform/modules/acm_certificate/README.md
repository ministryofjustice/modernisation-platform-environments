Create an AWS ACM certificate with DNS validation against zones in current
account, core-vpc account or core-network-shared-services account. Ensure
the validation map contains entries for both the `domain_name` and all
entries within `subject_alternate_names`.

If there are DNS zones where validation records cannot be created by the
module, the certificate is created in a 2 step process.

Step 1: Create the certificate. Create any external DNS entries given
in the `validation_records_external` output.
Step 2: Set the `external_validation_records_created` variable to true
to validate the certificate.

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
      renewal-alert = {
        comparison_operator = "LessThanThreshold"
        evaluation_periods  = "1"
        datapoints_to_alarm = "1"
        metric_name         = "DaysToExpiry"
        namespace           = "AWS/CertificateManager"
        period              = "86400"
        statistic           = "Minimum"
        threshold           = "14"
        alarm_description   = "Triggers if an ACM certificate has not automatically renewed and is expiring soon. Automatic renewal should happen 60 days prior to expiration."
      }
    }
  }
}

module "acm_certificate" {
  source = "./modules/acm_certificate"

  providers = {
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }

  name                    = "wildcard environment cert"
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

  cloudwatch_metric_alarms_acm = {
    renewal-alert = {
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = "1"
      datapoints_to_alarm = "1"
      metric_name         = "DaysToExpiry"
      namespace           = "AWS/CertificateManager"
      period              = "86400"
      statistic           = "Minimum"
      threshold           = "14"
      alarm_description   = "Triggers if an ACM certificate has not automatically renewed and is expiring soon. Automatic renewal should happen 60 days prior to expiration."
    }
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

With the alarm settings - don't forget to set your own `aws_sns_topic` values.
