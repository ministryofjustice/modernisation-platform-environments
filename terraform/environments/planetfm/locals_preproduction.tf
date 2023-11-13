# nomis-preproduction environment settings
locals {

  # baseline config
  preproduction_config = {
    baseline_ec2_instances = {
      # database server
      pp-cafm-db-a = merge(local.database_ec2, {
        config = merge(local.database_ec2.config, {
          ami_name          = "pp-cafm-db-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.database_ec2.instance, {
          instance_type = "r6i.xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 250 }
          "/dev/sdc"  = { type = "gp3", size = 50 }
          "/dev/sdd"  = { type = "gp3", size = 250 }
          "/dev/sde"  = { type = "gp3", size = 50 }
          "/dev/sdf"  = { type = "gp3", size = 250 }
          "/dev/sdg"  = { type = "gp3", size = 200 }
        }
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.database_ec2.tags, {
          description       = "copy of PPFDW0030 for planetfm ${local.environment}"
          app-config-status = "pending"
          ami               = "pp-cafm-db-a"
        })
      })

      # web servers
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
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.web_ec2.tags, {
          description       = "copy of PPFWW0005 for planetfm ${local.environment}"
          ami               = "pp-cafm-w-5-a"
          app-config-status = "pending"
        })
      })
    }
  }
}
