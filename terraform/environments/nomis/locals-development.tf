# nomis-development environment settings
locals {
  nomis_development = {
    # vars common across ec2 instances
    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    # cloud watch log groups
    log_groups = {
      session-manager-logs = {
        retention_days = 90
      }
      cwagent-var-log-messages = {
        retention_days = 30
      }
      cwagent-var-log-secure = {
        retention_days = 90
      }
      cwagent-nomis-autologoff = {
        retention_days = 90
      }
      cwagent-weblogic-logs = {
        retention_days = 30
      }
      cwagent-windows-system = {
        retention_days = 30
      }
    }

    databases = {
    }
    weblogics          = {}
    ec2_test_instances = {}
    ec2_test_autoscaling_groups = {
    }
    ec2_jumpservers = {
    }
  }

  # baseline config
  development_config = {

    baseline_ec2_autoscaling_groups = {

      dev-redhat-rhel79 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "RHEL-7.9_HVM-*"
          ami_owner                 = "309956199498"
          instance_profile_policies = local.ec2_common_managed_policies
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        tags = {
          description = "For testing official RedHat RHEL7.9 image"
          os-type     = "Linux"
          component   = "test"
        }
      }

      dev-base-rhel79 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                  = "base_rhel_7_9_*"
          instance_profile_policies = local.ec2_common_managed_policies
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
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
          ami_name                  = "base_rhel_6_10*"
          instance_profile_policies = local.ec2_common_managed_policies
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default_rhel6, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
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
          instance_profile_policies     = local.ec2_common_managed_policies
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-jumpserver"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        user_data_raw = base64encode(templatefile("./templates/jumpserver-user-data.yaml", { S3_BUCKET = module.s3-bucket.bucket.id }))
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 2
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
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
