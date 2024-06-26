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

    cloudwatch_metric_alarms = merge(
      module.baseline_presets.cloudwatch_metric_alarms.ec2,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_os,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_service_status_app,
      module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd_oracle_db_connected,
    )

    ec2_autoscaling_groups = {
      test-oem = merge(local.oem_ec2_default, {
        autoscaling_group = merge(local.oem_ec2_default.autoscaling_group, {
          desired_capacity = 0
        })
        user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
          args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.oem_ec2_default.tags, {
          oracle-sids = "EMREP TRCVCAT"
        })
      })
    }

    ec2_instances = {
      test-oem-a = merge(local.oem_ec2_default, {
        cloudwatch_metric_alarms = merge(
          local.oem_ec2_cloudwatch_metric_alarms.standard,
          local.oem_ec2_cloudwatch_metric_alarms.backup,
        )
        config = merge(local.oem_ec2_default.config, {
          availability_zone = "eu-west-2a"
        })
        user_data_cloud_init = merge(local.oem_ec2_default.user_data_cloud_init, {
          args = merge(local.oem_ec2_default.user_data_cloud_init.args, {
            branch = "45027fb7482eb7fb601c9493513bb73658780dda" # 2023-08-11
          })
        })
        tags = merge(local.oem_ec2_default.tags, {
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
      "/oracle/oem"              = local.oem_secretsmanager_secrets
      "/oracle/database/EMREP"   = local.oem_secretsmanager_secrets
      "/oracle/database/TRCVCAT" = local.oem_secretsmanager_secrets
    }
  }
}
