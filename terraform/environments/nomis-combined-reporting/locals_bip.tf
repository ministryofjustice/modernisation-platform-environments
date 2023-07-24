locals {

  bip_ssm_parameters = {
      prefix = "/bi-platform/"
      parameters = {
        bobj_password     = { description = "bobj account password" }
        oracle_password   = { description = "oracle account password" }
        product_key       = { description = "BIP product key" }
      }
    }

  bi-platform_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name          = "base_rhel_8_5_*"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t3.large"
      vpc_security_group_ids = ["private"]
    })
    
    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default
    ebs_volumes = {
      "/dev/sdb" = { type = "gp3", size = 100 }
      "/dev/sds" = { type = "gp3", size = 100 }
    }
    tags = {
      description = "ncr bip webtier component"
      ami         = "base_rhel_8_5"
      os-type     = "Linux"
      server-type = "ncr-bip"
    }
  }

}