locals {
  business_unit       = var.networking[0].business-unit
  region              = "eu-west-2"
  availability_zone_1 = "eu-west-2a"
  availability_zone_2 = "eu-west-2b"

  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }
  baseline_environment_config = local.environment_configs[local.environment]

  baseline_route53_zones = {
    "${local.environment}.nomis.az.justice.gov.uk" = {}
  }

  baseline_acm_certificates = {
    nomis_wildcard_cert = {
      # domain_name limited to 64 chars so use modernisation platform domain for this
      # and put the wildcard in the san
      domain_name = module.environment.domains.public.modernisation_platform
      subject_alternate_names = [
        "*.${module.environment.domains.public.application_environment}",
        "*.${local.environment}.nomis.az.justice.gov.uk"
      ]
      cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso"].acm_default
      tags = {
        description = "wildcard cert for ${module.environment.domains.public.application_environment} and ${local.environment}.nomis.az.justice.gov.uk domain"
      }
    }
  }

  autoscaling_schedules_default = {
    "scale_up" = {
      recurrence = "0 7 * * Mon-Fri"
    }
    "scale_down" = {
      desired_capacity = 0
      recurrence       = "0 19 * * Mon-Fri"
    }
  }
}

