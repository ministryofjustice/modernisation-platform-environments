locals {

  baseline_presets_production = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "hmpps-oem-production"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    ec2_instances = {
      prod-oem-a = merge(local.ec2_instances.oem, {
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
          oracle-sids = "EMREP PRCVCAT"
        })
      })
    }

    route53_zones = {
      "hmpps-production.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "oem.hmpps-oem", type = "CNAME", ttl = "300", records = ["prod-oem-a.hmpps-oem.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/oem"              = local.secretsmanager_secrets.oem
      "/oracle/database/EMREP"   = local.secretsmanager_secrets.oem
      "/oracle/database/PRCVCAT" = local.secretsmanager_secrets.oem
    }
  }
}
