# nomis-preproduction environment settings
locals {

  # baseline config
  preproduction_config = {
    baseline_ec2_instances = {
      pp-cafm-w-5-a = merge(local.web_ec2, {
        config = merge(local.web_ec2.config, {
          ami_name          = "pp-cafm-w-5-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.web_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        tags = merge(local.web_ec2.tags, {
          description = "copy of PPFWW0005 for planetfm ${local.environment}"
          ami         = "pp-cafm-w-5-a"
        })
      })
    }
  }
}
