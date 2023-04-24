# environment specific settings
locals {
  development_config = {

    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    baseline_bastion_linux = {
      # public_key_data = local.public_key_data.keys[local.environment]
      # tags            = local.tags
    }


    baseline_s3_buckets = {

    }

    baseline_ec2_instances = {
    }

    baseline_ec2_autoscaling_groups = {

      "dev-${application_name}-db" = merge(local.database, {
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags                  = local.database_tags
      })
    }

    baseline_acm_certificates = {
      "${application_name}_wildcard_cert" = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.dev.${module.environment.domains.public.short_name}", # "dev.oasys.service.justice.gov.uk"
          "*.dev.${application_name}.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso"].acm_default
        tags = {
          description = "wildcard cert for ${application_name} ${local.environment} domains"
        }
      }
    }

    baseline_lbs = {
    }

    baseline_route53_zones = {
    }
  }
}


