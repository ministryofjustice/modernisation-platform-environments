# csr-development environment settings
locals {

  baseline_presets_development = {
    options = {
      cloudwatch_metric_oam_links_ssm_parameters = [] # disable in dev as environment gets nuked
      cloudwatch_metric_oam_links                = [] # disable in dev as environment gets nuked
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    ec2_autoscaling_groups = {
      dev-base-ol85 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_ol_8_5_*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["database"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing our base OL8.5 base image"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-ol-8-5"
        }
      }

      dev-tst = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "base_windows_server_2012_r2_release_2023-*"
          ami_owner                     = "374269020027"
          ebs_volumes_copy_all_from_ami = false
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["CSRWebServerPolicy"])
          user_data_raw                 = base64encode(file("./templates/user-data.yaml"))
        })
        cloudwatch_metric_alarms = {}
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["app", "domain", "jumpserver"]
          instance_type          = "t3.medium"
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 192 } # minimum size has to be 128 due to snapshot sizes
        }
        tags = {
          description = "Test AWS AMI Windows Server 2012 R2"
          os-type     = "Windows"
          component   = "appserver"
          server-type = "test-server"
        }
      }
      dev-win-2022 = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2024-*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/user-data.yaml"))
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["CSRWebServerPolicy"])
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["domain", "jumpserver"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        cloudwatch_metric_alarms = {}
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Windows Server 2022 for testing"
          os-type     = "Windows"
          component   = "test"
        }
      }
    }

    secretsmanager_secrets = {
      "/activedirectory/devtest/aws-lambda" = {
        secrets = {
          passwords = { description = "active directory lambda service account" }
        }
      }
    }
  }
}
