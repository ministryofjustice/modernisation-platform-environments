locals {

  # baseline config
  preproduction_config = {

    # Instance Type Defaults for preproduction
    # instance_type_defaults = {
    #   web = "m6i.xlarge" # 4 vCPUs, 16GB RAM x 2 instances
    #   boe = "m4.2xlarge" # 8 vCPUs, 32GB RAM x 2 instances
    #   bods = "m6i.2xlarge" # 8 vCPUs, 32GB RAM x 1 instance, reduced RAM as Azure usage doesn't warrant higher RAM
    # }
    baseline_acm_certificates = {
      oasys_national_reporting_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = "modernisation-platform.service.justice.gov.uk"
        subject_alternate_names = [
          "*.oasys-national-reporting.hmpps-preproduction.modernisation-platform.service.justice.gov.uk",
          "preproduction.reporting.oasys.service.justice.gov.uk",
          "*.preproduction.reporting.oasys.service.justice.gov.uk",
          "onr.pp-oasys.az.justice.gov.uk",
        ]
        external_validation_records_created = false
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "Wildcard certificate for the ${local.environment} environment"
        }
      }
    }

    baseline_route53_zones = {
      "preproduction.reporting.oasys.service.justice.gov.uk" = {}
    }
  }
}
