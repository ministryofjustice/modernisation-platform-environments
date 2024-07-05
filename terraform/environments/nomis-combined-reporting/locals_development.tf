locals {

  baseline_presets_development = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty               = "nomis_nonprod_alarms"
          dba_pagerduty               = "hmpps_shef_dba_non_prod"
          dba_high_priority_pagerduty = "hmpps_shef_dba_non_prod"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    ec2_autoscaling_groups = {
      dev-ncr-client-a = merge(local.jumpserver_ec2_default, {
        autoscaling_group     = module.baseline_presets.ec2_autoscaling_group.default_with_warm_pool
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
      })
    }

    route53_zones = {
      "development.reporting.nomis.service.justice.gov.uk" = {
      }
    }
  }
}
