# nomis-preproduction environment settings
locals {

  # baseline config
  preproduction_config = {
      test-srv-1 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "ami-055c4a9db6f698661" # Microsoft Windows Server 2019 Base
          ami_owner                     = "self"
          ebs_volumes_copy_all_from_ami = false
          # user_data_raw                 = base64encode(file("./templates/app-server-user-data.yaml"))
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["CSRWebServerPolicy"])
        })

        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["migration-web-sg"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 256 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 1 # set to 0 while testing
        })
        tags = {
          description = "Test Windows Web Server 2012 R2 includes Ec2LaunchV2 NVMe and PV drivers"
          os-type     = "Windows"
          component   = "Test"
          server-type = "test-windows-server"
        }
    }
  }
}


      
