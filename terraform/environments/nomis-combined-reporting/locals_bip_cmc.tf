locals {
  bip_cmc_ssm_parameters = {
    prefix = "/bip-cmc/"
    parameters = {
      product_key          = { description = "BIP product key" }
      cms_cluster_key      = { description = "CMS Cluster Key" }
      cms_admin_password   = { description = "CMS Admin Password" }
      cms_db_password      = { description = "CMS DB password" }
      auditing_db_password = { description = "Auditing DB password" }
      lcm_password         = { description = "LCM Password" }
    }
  }

  bip_cmc_secretsmanager_secrets = {
    secrets = {
      passwords = {}
    }
  }

  bip_cmc_ec2_default = {

    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "base_rhel_8_5_*"
      ssm_parameters_prefix     = "bip-cmc/"
      iam_resource_names_prefix = "ec2-bip-cmc"
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      instance_type          = "t3.large"
      vpc_security_group_ids = ["private"]
    })

    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default
    ebs_volumes = {
      "/dev/sdb" = { type = "gp3", size = 100 }
      "/dev/sdc" = { type = "gp3", size = 100 }
      "/dev/sds" = { type = "gp3", size = 100 }
    }

    route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external

    tags = {
      description = "ncr bip cmc webtier component"
      ami         = "base_rhel_8_5"
      os-type     = "Linux"
      server-type = "ncr-bip-cmc"
      component   = "web"
    }
  }
}