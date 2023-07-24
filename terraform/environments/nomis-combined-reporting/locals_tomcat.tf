locals {

  tomcat_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name = "base_rhel_8_5_*"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t3.large"
      vpc_security_group_ids = ["private"]
    })
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default

    tags = {
      description = "ncr tomcat webtier component"
      ami         = "base_rhel_8_5"
      os-type     = "Linux"
      server-type = "ncr-tomcat"
    }
  }

}