locals {

  baseline_presets_development = {
    options = {
      # disabling some features in development as the environment may get nuked
      cloudwatch_metric_oam_links_ssm_parameters = []
      cloudwatch_metric_oam_links                = []
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    ec2_autoscaling_groups = {
      dev-ncr-client-a = merge(local.ec2_autoscaling_groups.jumpserver, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.jumpserver.autoscaling_group, {
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
