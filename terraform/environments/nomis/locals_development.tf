# nomis-development environment settings
locals {
  nomis_development = {
    # vars common across ec2 instances
    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }
  }

  # baseline config
  development_config = {
    baseline_acm_certificates = {
      nomis_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.${local.environment}.nomis.az.justice.gov.uk",
        ]
        cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso_pagerduty"].acm_default
        tags = {
          description = "wildcard cert for ${module.environment.domains.public.application_environment} and ${local.environment}.nomis.az.justice.gov.uk domain"
        }
      }
    }

    baseline_ec2_autoscaling_groups = {

      dev-redhat-rhel79 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "RHEL-7.9_HVM-*"
          ami_owner         = "309956199498"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing official RedHat RHEL7.9 image"
          os-type     = "Linux"
          component   = "test"
        }
      }

      dev-base-rhel85 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_rhel_8_5_*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "nomis/DSOS-1893/re-enable-warm-pools"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default_with_ready_hook, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing our base RHEL8.5 base image"
          ami         = "base_rhel_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-rhel85"
        }
      }

      dev-base-rhel79 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_rhel_7_9_*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "nomis/DSOS-1893/re-enable-warm-pools"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default_with_ready_hook, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing our base RHEL7.9 base image"
          ami         = "base_rhel_7_9"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-rhel79"
        }
      }

      dev-base-rhel610 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_rhel_6_10*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default_rhel6, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "nomis/DSOS-1893/re-enable-warm-pools"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default_with_ready_hook, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing our base RHEL6.10 base image"
          ami         = "base_rhel_6_10"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-rhel610"
        }
      }

      dev-jumpserver-2022 = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "nomis_windows_server_2022_jumpserver_release_*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/jumpserver-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-jumpserver"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Windows Server 2022 Jumpserver for NOMIS"
          os-type     = "Windows"
          component   = "jumpserver"
          server-type = "nomis-jumpserver"
        }
      }
    }
  }
}
