locals {
  jumpserver_ec2 = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name          = "base_windows_server_2012_r2_release_2024-*"
      ami_owner         = "374269020027"
      availability_zone = "eu-west-2a"
      # ami has unwanted ephemeral device, don't copy all the ebs_volumes
      ebs_volumes_copy_all_from_ami = false
      user_data_raw                 = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
    })
    ebs_volumes = {
      "/dev/sda1" = { type = "gp3", size = 200 }
    }
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "m4.large"
      vpc_security_group_ids = ["private-jumpserver"]
    })
    tags = {
      description            = "Windows Server 2012 R2 client testing for NART"
      instance-access-policy = "full"
      os-type                = "Windows"
      component              = "test"
      server-type            = "OnrClient"
      backup                 = "false" # no need to backup as these shouldn't contain persistent data
    }
  }
}
