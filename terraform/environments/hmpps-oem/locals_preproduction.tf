locals {

  baseline_presets_preproduction = {
    options = {
      enable_ec2_delius_dba_secrets_access = true

      sns_topics = {
        pagerduty_integrations = {
          azure-fixngo-pagerduty              = "az-noms-production-1-alerts"
          corporate-staff-rostering-pagerduty = "corporate-staff-rostering-preproduction"
          dso-pipelines-pagerduty             = "dso-pipelines"
          hmpps-domain-services-pagerduty     = "hmpps-domain-services-preproduction"
          nomis-combined-reporting-pagerduty  = "nomis-combined-reporting-preproduction"
          nomis-pagerduty                     = "nomis-preproduction"
          oasys-national-reporting-pagerduty  = "oasys-national-reporting-preproduction"
          oasys-pagerduty                     = "oasys-preproduction"
          pagerduty                           = "hmpps-oem-preproduction"
          planetfm-pagerduty                  = "planetfm-preproduction"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    ec2_instances = {

      preprod-oem-a = merge(local.ec2_instances.oem, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.oem.cloudwatch_metric_alarms,
          local.cloudwatch_metric_alarms_endpoint_monitoring
        )
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
