locals {

  baseline_presets_test = {
    options = {
      cloudwatch_dashboard_default_widget_groups = flatten([
        local.cloudwatch_dashboard_default_widget_groups,
        "github_workflows", # metrics are only pushed into test account
      ])
      enable_ec2_delius_dba_secrets_access = true

      sns_topics = {
        pagerduty_integrations = {
          azure-fixngo-pagerduty          = "az-noms-dev-test-environments-alerts"
          dso-pipelines-pagerduty         = "dso-pipelines"
          hmpps-domain-services-pagerduty = "hmpps-domain-services-test"
          nomis-pagerduty                 = "nomis-test"
          oasys-pagerduty                 = "oasys-test"
          pagerduty                       = "hmpps-oem-test"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    cloudwatch_metric_alarms = merge(
      module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["dso-pipelines-pagerduty"].github
    )

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
