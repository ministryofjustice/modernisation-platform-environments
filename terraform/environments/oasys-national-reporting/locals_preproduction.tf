locals {

  baseline_presets_preproduction = {
    options = {
      #   pagerduty_integrations = {
      #     dso_pagerduty               = "oasys_alarms"
      #     dba_pagerduty               = "hmpps_shef_dba_low_priority"
      #     dba_high_priority_pagerduty = "hmpps_shef_dba_low_priority"
      # }
    }
  }


  # please keep resources in alphabetical order
  baseline_preproduction = {

    # Instance Type Defaults for preproduction
    # instance_type_defaults = {
    #   web = "m6i.xlarge" # 4 vCPUs, 16GB RAM x 2 instances
    #   boe = "m4.2xlarge" # 8 vCPUs, 32GB RAM x 2 instances
    #   bods = "m6i.2xlarge" # 8 vCPUs, 32GB RAM x 1 instance, reduced RAM as Azure usage doesn't warrant higher RAM
    # }

    acm_certificates = {
      oasys_national_reporting_wildcard_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.oasys-national-reporting.hmpps-preproduction.modernisation-platform.service.justice.gov.uk",
          "preproduction.reporting.oasys.service.justice.gov.uk",
          "*.preproduction.reporting.oasys.service.justice.gov.uk",
          "onr.pp-oasys.az.justice.gov.uk",
        ]
        tags = {
          description = "Wildcard certificate for the preproduction environment"
        }
      }
    }

    route53_zones = {
      "preproduction.reporting.oasys.service.justice.gov.uk" = {}
    }
  }
}
