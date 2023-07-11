locals {

  xtag_weblogic_ssm_parameters = {
    prefix = "/weblogic/"
    parameters = {
      admin_username = { description = "weblogic admin username" }
      admin_password = { description = "weblogic admin password" }
      db_username    = { description = "nomis database xtag username" }
      db_password    = { description = "nomis database xtag password" }
    }
  }

  xtag_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name          = "base_rhel_7_9_*"
      availability_zone = null
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t2.large"
      vpc_security_group_ids = ["private-web"]
    })
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default

    tags = {
      description = "nomis XTAG weblogic component"
      ami         = "base_rhel_7_9"
      os-type     = "Linux"
      server-type = "nomis-xtag"
    }
  }

}
