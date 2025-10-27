locals {

  baseline_presets_preproduction = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "planetfm-preproduction"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    cloudwatch_dashboards = {
      "CloudWatch-Default" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.network_lb,
          local.cloudwatch_dashboard_widget_groups.db,
          local.cloudwatch_dashboard_widget_groups.app,
          local.cloudwatch_dashboard_widget_groups.web,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
        ]
      }
    }

    ec2_instances = {

      # app servers
      pp-cafm-a-10-b = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pp-cafm-a-10-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
        }
        instance = merge(local.ec2_instances.app.instance, {
          disable_api_termination = true
          instance_type           = "t3.large"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami                 = "pp-cafm-a-10-b"
          description         = "RDS Session Host and CAFM App Server/PFME Licence Server"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPFAW0010"
        })
      })

      pp-cafm-a-11-a = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pp-cafm-a-11-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
        }
        instance = merge(local.ec2_instances.app.instance, {
          disable_api_termination = true
          instance_type           = "t3.large"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami                 = "pp-cafm-a-11-a"
          description         = "RDS session host and app server"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPFAW011"
        })
      })

      # database servers
      pp-cafm-db-a = merge(local.ec2_instances.db, {
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "pp-cafm-db-a"
          availability_zone = "eu-west-2a"
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
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
          instance_type           = "r6i.xlarge"
        })
        tags = merge(local.ec2_instances.db.tags, {
          ami                 = "pp-cafm-db-a"
          description         = "SQL Server"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPFDW0030"
        })
      })

      # web servers
      pp-cafm-w-4-b = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pp-cafm-w-4-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
        }
        instance = merge(local.ec2_instances.web.instance, {
          disable_api_termination = true
          instance_type           = "t3.large"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami                 = "pp-cafm-w-4-b"
          description         = "Web Portal Server"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPFWW0004"
        })
      })

      pp-cafm-w-5-a = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pp-cafm-w-5-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
        }
        instance = merge(local.ec2_instances.web.instance, {
          disable_api_termination = true
          instance_type           = "t3.large"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami                 = "pp-cafm-w-5-a"
          description         = "Migrated server PPFWW0005 Web Portal Server"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPFWW0005"
        })
      })
    }

    lbs = {
      pp-cafmwebx = merge(local.lbs.web, {
        instance_target_groups = {
          pp-cafmwebx-https = merge(local.lbs.web.instance_target_groups.https, {
            attachments = [
              { ec2_instance_name = "pp-cafm-w-4-b" },
              { ec2_instance_name = "pp-cafm-w-5-a" },
            ]
          })
        }

        listeners = {
          https = merge(local.lbs.web.listeners.https, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-cafmwebx-https"
            }
          })
        }
      })
    }

    route53_zones = {
      "pp-cafmwebx.az.justice.gov.uk" = {
        lb_alias_records = [
          { name = "", type = "A", lbs_map_key = "pp-cafmwebx" },
        ]
      }
      "pp.planetfm.service.justice.gov.uk" = {
        records = [
          { name = "_658adffab7a58a4d5a86804a2b6eb2f7", type = "CNAME", ttl = 86400, records = ["_c649cb794d2fa2e1ac4d3f6fb4e1c8a7.mhbtsbpdnt.acm-validations.aws"] },
          { name = "cafmtx", type = "CNAME", ttl = 3600, records = ["rdweb1.preproduction.hmpps-domain.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "cafmwebx", type = "A", lbs_map_key = "pp-cafmwebx" },
        ]
      }
    }
  }
}
