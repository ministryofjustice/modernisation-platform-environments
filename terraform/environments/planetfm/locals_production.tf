# nomis-production environment settings
locals {

  # baseline config
  production_config = {
    baseline_route53_zones = {
      "planetfm.service.justice.gov.uk" = {
        records = [
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1128.awsdns-13.org", "ns-2027.awsdns-61.co.uk", "ns-854.awsdns-42.net", "ns-90.awsdns-11.com"] },
          { name = "pp", type = "NS", ttl = "86400", records = ["ns-1407.awsdns-47.org", "ns-1645.awsdns-13.co.uk", "ns-63.awsdns-07.com", "ns-730.awsdns-27.net"] },
        ]
      }
    }
    baseline_acm_certificates = {
      planetfm_wildcard_cert = {
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.planetfm.service.justice.gov.uk",
          "cafmwebx.az.justice.gov.uk",
          "cafmwebx2.az.justice.gov.uk",
          "cafmtx.az.justice.gov.uk",
          "cafmtrainweb.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for planetfm ${local.environment} domains"
        }
      }
    }
  }
}
