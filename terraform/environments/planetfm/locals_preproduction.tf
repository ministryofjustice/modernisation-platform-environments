# nomis-preproduction environment settings
locals {

  # baseline config
  preproduction_config = {
    baseline_ec2_instances = {
      # database server
      pp-cafm-db-a = merge(local.defaults_database_ec2, {
        config = merge(local.defaults_database_ec2.config, {
          ami_name          = "pp-cafm-db-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_database_ec2.instance, {
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
        tags = merge(local.defaults_database_ec2.tags, {
          description       = "copy of PPFDW0030 SQL Server"
          app-config-status = "pending"
          ami               = "pp-cafm-db-a"
        })
      })

      # app servers
      pp-cafm-a-10-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-cafm-a-10-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.defaults_app_ec2.tags, {
          description       = "Migrated server PPFAW0010 PFME Licence Server"
          ami               = "pp-cafm-a-10-b"
          app-config-status = "pending"
        })
      })

      pp-cafm-a-11-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-cafm-a-11-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.defaults_app_ec2.tags, {
          description       = "Migrated server PPFAW011 RDS session host app server"
          ami               = "pp-cafm-a-11-a"
          app-config-status = "pending"
        })
      })


      # web servers
      pp-cafm-w-2-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-cafm-w-2-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.defaults_web_ec2.tags, {
          description       = "Migrated server PPFWW0002 Web Access Server / RDS Gateway Server"
          ami               = "pp-cafm-w-2-b"
          app-config-status = "pending"
        })
      })

      pp-cafm-w-3-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-cafm-w-2-b"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.defaults_web_ec2.tags, {
          description       = "Migrated server PPFWW0003 Web Access Server / RDS Gateway Server"
          ami               = "pp-cafm-w-2-b"
          app-config-status = "pending"
        })
      })

      pp-cafm-w-4-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-cafm-w-4-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.large"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
        tags = merge(local.defaults_web_ec2.tags, {
          description       = "Migrated server PPFWW0004 Web Portal Server"
          ami               = "pp-cafm-w-4-b"
          app-config-status = "pending"
        })
      })

      # pp-cafm-w-5-a = merge(local.defaults_web_ec2, {
      #   config = merge(local.defaults_web_ec2.config, {
      #     ami_name          = "pp-cafm-w-5-a"
      #     availability_zone = "${local.region}a"
      #   })
      #   instance = merge(local.defaults_web_ec2.instance, {
      #     instance_type = "t3.large"
      #   })
      #   ebs_volumes = {
      #     "/dev/sda1" = { type = "gp3", size = 128 } # root volume
      #     "/dev/sdb"  = { type = "gp3", size = 100 }
      #   }
      #   cloudwatch_metric_alarms = {} # TODO: remove this later when @Dominic has added finished changing the alarms
      #   tags = merge(local.defaults_web_ec2.tags, {
      #     description       = "Migrated server PPFWW0005 Web Portal Server"
      #     ami               = "pp-cafm-w-5-a"
      #     app-config-status = "pending"
      #   })
      # })
    }
  }
}
