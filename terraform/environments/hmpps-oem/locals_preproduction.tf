# nomis-preproduction environment settings
locals {

  # cloudwatch monitoring config
  preproduction_cloudwatch_monitoring_options = {
    enable_cloudwatch_monitoring_account = false
  }

  # baseline presets config
  preproduction_baseline_presets_options = {
    sns_topics = {
      pagerduty_integrations = {
        dba_pagerduty = "hmpps_shef_dba_low_priority"
        dso_pagerduty = "nomis_nonprod_alarms"
      }
    }
  }

  # baseline config
  preproduction_config = {

    baseline_secretsmanager_secrets = {
      "/oracle/oem"               = local.oem_secretsmanager_secrets
      "/oracle/database/EMREP"    = local.oem_secretsmanager_secrets
      "/oracle/database/PPRCVCAT" = local.oem_secretsmanager_secrets
    }

    baseline_ec2_instances = {
      preprod-oem-a = merge(local.oem_ec2_default, {
        cloudwatch_metric_alarms = merge(
          local.oem_ec2_cloudwatch_metric_alarms.standard,
          local.oem_ec2_cloudwatch_metric_alarms.backup,
        )
        config = merge(local.oem_ec2_default.config, {
          availability_zone = "eu-west-2a"
        })
        user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
          args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.oem_ec2_default.tags, {
          oracle-sids = "EMREP PPRCVCAT"
        })
      })
    }

    baseline_route53_zones = {
      "hmpps-preproduction.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "oem.hmpps-oem", type = "CNAME", ttl = "300", records = ["preprod-oem-a.hmpps-oem.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }
  }
}
