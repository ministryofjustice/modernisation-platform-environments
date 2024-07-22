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

    # Instance Type Defaults for preproduction
    # instance_type_defaults = {
    #   web = "m6i.xlarge" # 4 vCPUs, 16GB RAM x 2 instances
    #   boe = "m4.2xlarge" # 8 vCPUs, 32GB RAM x 2 instances
    #   bods = "m6i.2xlarge" # 8 vCPUs, 32GB RAM x 1 instance, reduced RAM as Azure usage doesn't warrant higher RAM
    # }
    ec2_instances = {
      pp-onr-bods-1-a = merge(local.ec2_instances.bods, {
        config = merge(local.ec2_instances.bods.config, {
          ami_name          = "hmpps_windows_server_2019_release_2024-07-02T00-00-37.755Z"
          ami_owner         = "self"
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.bods.instance, {
          instance_type = "m6i.2xlarge"
        })
        # volumes are a direct copy of BODS in NCR
        ebs_volumes = merge(local.ec2_instances.bods.ebs_volumes, {
          "/dev/sda1" = { type = "gp3", size = 100 }
          "/dev/sdb"  = { type = "gp3", size = 100 }
          "/dev/sdc"  = { type = "gp3", size = 100 }
          "/dev/sds"  = { type = "gp3", size = 100 }
        })
      })
    }

    route53_zones = {
      "preproduction.reporting.oasys.service.justice.gov.uk" = {}
    }
  }
}
