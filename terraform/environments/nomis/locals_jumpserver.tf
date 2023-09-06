locals {
  jumpserver_ec2_default = {
    # ami has unwanted ephemeral device, don't copy all the ebs_volumes
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                      = "hmpps_windows_server_2022_release_2023-09-02T00-00-45.734Z"
      availability_zone             = null
      ebs_volumes_copy_all_from_ami = false
      user_data_raw = base64encode(templatefile("./templates/jumpserver-user-data.yaml.tftpl", {
        ie_compatibility_mode_site_list = join(",", [])
        ie_trusted_domains              = join(",", [])
        desktop_shortcuts               = join(",", [])
      }))
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t3.large"
      vpc_security_group_ids = ["private-jumpserver"]
    })
    ebs_volumes = {
      "/dev/sda1" = { type = "gp3", size = 100 }
    }
    autoscaling_group     = module.baseline_presets.ec2_autoscaling_group.default_with_warm_pool
    autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
    tags = {
      description = "Windows Server 2022 Jumpserver for NOMIS"
      os-type     = "Windows"
      component   = "jumpserver"
      server-type = "nomis-jumpserver"
    }
  }
}
