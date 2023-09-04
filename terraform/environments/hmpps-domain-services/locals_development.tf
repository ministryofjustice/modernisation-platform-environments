# nomis-development environment settings
locals {

  # baseline config
  development_config = {

    baseline_ec2_autoscaling_groups = {
      
      dev-windows-2022 = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-web"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        autoscaling_group     = module.baseline_presets.ec2_autoscaling_group.default
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Windows Server 2022 for connecting to Azure domain"
          os-type     = "Windows"
          component   = "test"
          server-type = "hmpps-windows_2022"
        }
      }

    }

  }
}