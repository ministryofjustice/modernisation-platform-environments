locals {

  baseline_presets_development = {
    options = {
      # disabling some features in development as the environment may get nuked
      cloudwatch_metric_oam_links_ssm_parameters = []
      cloudwatch_metric_oam_links                = []

      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty               = "nomis_nonprod_alarms"
          dba_pagerduty               = "hmpps_shef_dba_non_prod"
          dba_high_priority_pagerduty = "hmpps_shef_dba_non_prod"
        }
      }
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

    ec2_instance_linux = {
      dev-ncr-cms-a = merge(local.ec2_instances.bip_app, {
        #cloudwatch_metric_alarms = local.cloudwatch_metric_alarms.bip_app # comment in when commissioned
        config = merge(local.ec2_instances.bip_app.config, {
          ami_name          = "base_rhel_8_5_2024-05-01T00-00-19.643Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip_app.config.instance_profile_policies, [
            "Ec2PPReportingPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip_app.instance, {
          instance_type = "m6i.xlarge",
        })
        user_data_cloud_init = merge(local.ec2_instances.bip_app.user_data_cloud_init, {        
          args = {
            branch       = "DSO/DSOS-2909/fix-oracle-19c-client-role"
            ansible_args = "--tags ec2provision"
          }
          scripts = [ # paths are relative to templates/ dir
            "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent.sh",
            "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
            "../../../modules/baseline_presets/ec2-user-data/post-ec2provision.sh",
          ]
        })
        tags = merge(local.ec2_instances.bip_app.tags, {
          description                          = "TEST INSTANCE ONLY - DO NOT USE"
          instance-scheduling                  = "skip-scheduling"
          # node                                 = "1"
          # nomis-combined-reporting-environment = "pp"
          # type                                 = "management"
        })
      })
    }

    route53_zones = {
      "development.reporting.nomis.service.justice.gov.uk" = {
      }
    }
  }
}
