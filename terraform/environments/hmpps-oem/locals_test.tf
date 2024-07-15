locals {

  baseline_presets_test = {
    options = {
      enable_ec2_delius_dba_secrets_access = true

      sns_topics = {
        pagerduty_integrations = {
          dba_pagerduty = "hmpps_shef_dba_non_prod"
          dso_pagerduty = "nomis_nonprod_alarms"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    ec2_autoscaling_groups = {
      test-oem = merge(local.ec2_instances.oem, {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          force_delete        = true
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        cloudwatch_metric_alarms = {}
        tags = merge(local.ec2_instances.oem.tags, {
          oracle-sids = "EMREP TRCVCAT"
        })
      })
    }

    ec2_instances = {
      test-oem-a = merge(local.ec2_instances.oem, {
        config = merge(local.ec2_instances.oem.config, {
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.oem.instance, {
          disable_api_termination = true
        })
        user_data_cloud_init = merge(local.ec2_instances.oem.user_data_cloud_init, {
          args = merge(local.ec2_instances.oem.user_data_cloud_init.args, {
            branch = "45027fb7482eb7fb601c9493513bb73658780dda" # 2023-08-11
          })
        })
        tags = merge(local.ec2_instances.oem.tags, {
          oracle-sids = "EMREP TRCVCAT"
        })
      })
    }

    route53_zones = {
      "hmpps-test.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "oem.hmpps-oem", type = "CNAME", ttl = "300", records = ["test-oem-a.hmpps-oem.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/oem"              = local.secretsmanager_secrets.oem
      "/oracle/database/EMREP"   = local.secretsmanager_secrets.oem
      "/oracle/database/TRCVCAT" = local.secretsmanager_secrets.oem
    }
  }
}
