locals {
  development_config = {
    baseline_efs = {
      dev_efs = {
        access_points = {
          root = {
            posix_user = {
              gid            = 10003
              uid            = 10003
            }
            root_directory = {
              path = "/"
              creation_info = {
                owner_gid   = 10003
                owner_uid   = 10003
              }
            }
          }
        }
        #backup_policy_status = "DISABLED"
        file_system = {
          #availability_zone_name = "eu-west-2a"
          lifecycle_policy = {
            transition_to_ia                    = "AFTER_30_DAYS"
            #transition_to_primary_storage_class = "AFTER_1_ACCESS"
          }
        }
        mount_targets = [{
          subnet_name        = "private"
          availability_zones = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
          security_groups    = ["private"]
        }]
        #policy = [{
        #  sid    = "test"
        #  effect = "Allow"
        #  actions = [
        #    "elasticfilesystem:ClientMount",
        #    "elasticfilesystem:ClientWrite",
        #  ]
        #  resources = ["*"]
        #  conditions = [{
        #    test     = "Bool"
        #    variable = "aws:SecureTransport"
        #    values   = ["true"]
        #  }]
        #}]
        #tags = {
        #  foo = "bar"
        #}
      }
    }

    baseline_ec2_autoscaling_groups = {
      dev-base-rhel85 = {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 1
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
