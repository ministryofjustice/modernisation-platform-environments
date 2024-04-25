locals {
  development_config = {
    baseline_secretsmanager_secrets = {
      "/microsoft/AD/azure.noms.root" = {
        secrets = {
          passwords = {
            description = "domain passwords only accessible by this account"
          }
        }
      }
    }

    baseline_efs = {
      # dev_efs = {
      #   access_points = {
      #     root = {
      #       posix_user = {
      #         gid = 10003
      #         uid = 10003
      #       }
      #       root_directory = {
      #         path = "/"
      #         creation_info = {
      #           owner_gid   = 10003
      #           owner_uid   = 10003
      #           permissions = "0777"
      #         }
      #       }
      #     }
      #   }
      #   backup_policy_status = "DISABLED"
      #   file_system = {
      #     availability_zone_name = "eu-west-2a"
      #   }
      #   mount_targets = [{
      #     subnet_name        = "private"
      #     availability_zones = ["eu-west-2a"]
      #     security_groups    = ["private"]
      #   }]
      # }
    }

    baseline_fsx_windows = {
      # dev_fsx = {
      #   subnets = [{
      #     name               = "private"
      #     availability_zones = ["eu-west-2a"]
      #   }]
      #   security_groups     = ["private"]
      #   throughput_capacity = 8
      #   self_managed_active_directory = {
      #     dns_ips = [
      #       module.ip_addresses.mp_ip.ad-azure-dc-a,
      #       module.ip_addresses.mp_ip.ad-azure-dc-b,
      #     ]
      #     domain_name         = "azure.noms.root"
      #     username            = "blah"
      #     password_secret_arn = "arn:aws:secretsmanager:eu-west-2:161282055413:secret:/microsoft/AD/azure.noms.root/shared-passwords"
      #   }
      # }
    }

    baseline_ec2_autoscaling_groups = {
      dev-base-rhel85 = {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_rhel_8_5_*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        tags = {
          description = "For testing our base RHEL8.5 base image"
          ami         = "base_rhel_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-rhel85"
        }
      }
    }
  }
}
