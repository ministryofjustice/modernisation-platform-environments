locals {

  baseline_presets_preproduction = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          dba_pagerduty = "hmpps_shef_dba_low_priority"
          dso_pagerduty = "nomis_nonprod_alarms"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    ec2_instances = {

      preprod-oem-a = merge(local.ec2_instances.oem, {
        config = merge(local.ec2_instances.oem.config, {
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.oem.instance, {
          disable_api_termination = true
        })
        user_data_cloud_init = merge(local.ec2_instances.oem.user_data_cloud_init, {
          args = merge(local.ec2_instances.oem.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.oem.tags, {
          oracle-sids = "EMREP PPRCVCAT"
        })
      })
    }

    route53_zones = {
      "hmpps-preproduction.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "oem.hmpps-oem", type = "CNAME", ttl = "300", records = ["preprod-oem-a.hmpps-oem.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/oem"               = local.secretsmanager_secrets.oem
      "/oracle/database/EMREP"    = local.secretsmanager_secrets.oem
      "/oracle/database/PPRCVCAT" = local.secretsmanager_secrets.oem
    }
  }
}
