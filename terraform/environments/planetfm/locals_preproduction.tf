# nomis-preproduction environment settings
locals {

  # baseline config
  preproduction_config = {
    baseline_ec2_instances = {
      pp-cafm-w-5-a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "pp-cafm-w-5-a"
          ami_owner                     = "self"
          availability_zone             = "${local.region}a"
          ebs_volumes_copy_all_from_ami = false
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type           = "t3.large"
          disable_api_termination = true
          monitoring              = true
          vpc_security_group_ids  = ["domain", "web", "jumpserver"]
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        tags = {
          description = "copy of PPFWW0005 for planetfm ${local.environment}"
          os-type     = "Windows"
          ami         = "pp-cafm-w-5-a"
          component   = "web"
        }
      }
    }
  }
}
