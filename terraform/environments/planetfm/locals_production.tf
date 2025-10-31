locals {

  baseline_presets_production = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "planetfm-production"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

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

      "pd-cafm-db-a" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          {
            width         = 8
            height        = 8
            search_filter = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-cafm-db-a" }] }
            widgets = [
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_windows.free-disk-space-low,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.high-memory-usage,
              null,
            ]
          },
          {
            header_markdown = "## EBS PERFORMANCE"
            width           = 8
            height          = 8
            add_ebs_widgets = { iops = true, throughput = true }
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-cafm-db-a" }] }
            widgets         = []
          }
        ]
      }

      "pd-cafm-db-b" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          {
            width         = 8
            height        = 8
            search_filter = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-cafm-db-b" }] }
            widgets = [
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.cpu-utilization-high,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-in-bandwidth,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.network-out-bandwidth,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.instance-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.system-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2.attached-ebs-status-check-failed,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_instance_cwagent_windows.free-disk-space-low,
              module.baseline_presets.cloudwatch_dashboard_widgets.ec2_cwagent_windows.high-memory-usage,
              null,
            ]
          },
          {
            header_markdown = "## EBS PERFORMANCE"
            width           = 8
            height          = 8
            add_ebs_widgets = { iops = true, throughput = true }
            search_filter   = { ec2_tag = [{ tag_name = "Name", tag_value = "pd-cafm-db-b" }] }
            widgets         = []
          }
        ]
      }
    }

    ec2_instances = {
      # app servers
      pd-cafm-a-10-b = merge(local.ec2_instances.app, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.app.cloudwatch_metric_alarms,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows
        )
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pd-cafm-a-10-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 200 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          disable_api_termination = true
          instance_type           = "t3.xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami              = "pd-cafm-a-10-b"
          description      = "RDS Session Host and CAFM App Server/PFME Licence Server"
          pre-migration    = "PDFAW0010"
          update-ssm-agent = "patchgroup2"
        })
      })

      pd-cafm-a-11-a = merge(local.ec2_instances.app, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.app.cloudwatch_metric_alarms,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows,
        )
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pd-cafm-a-2022-image-20250806T1436"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 200 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          disable_api_termination = true
          instance_type           = "t3.xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          description      = "RDS session host and app server"
          update-ssm-agent = "patchgroup1"
          server-type      = "PlanetFMApp"
        })
      })

      pd-cafm-a-12-b = merge(local.ec2_instances.app, {
        cloudwatch_metric_alarms = {}
        #cloudwatch_metric_alarms = merge(
        #  local.ec2_instances.app.cloudwatch_metric_alarms,
        #  module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows
        #)
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pd-cafm-a-2022-image-20250806T1436"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 200 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          disable_api_termination = true
          instance_type           = "t3.xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          description      = "RDS session host and app Server"
          update-ssm-agent = "patchgroup2"
          server-type      = "PlanetFMApp"
        })
      })

      pd-cafm-a-13-a = merge(local.ec2_instances.app, {
        cloudwatch_metric_alarms = {}
        #cloudwatch_metric_alarms = merge(
        #  local.ec2_instances.app.cloudwatch_metric_alarms,
        #  module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows
        #)
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pd-cafm-a-2022-image-20250806T1436"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 200 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          disable_api_termination = true
          instance_type           = "t3.xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          description      = "RDS session host and app Server"
          update-ssm-agent = "patchgroup1"
          server-type      = "PlanetFMApp"
        })
      })

      pd-cafm-a-14-b = merge(local.ec2_instances.app, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.app.cloudwatch_metric_alarms,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows
        )
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pd-cafm-a-2022-image-20250806T1436"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 200 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          disable_api_termination = true
          instance_type           = "t3.xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          description      = "RDS session host and app Server"
          update-ssm-agent = "patchgroup2"
          server-type      = "PlanetFMApp"
        })
      })

      pd-cafm-a-15-a = merge(local.ec2_instances.app, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.app.cloudwatch_metric_alarms,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows
        )
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pd-cafm-a-2022-image-20250806T1436"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 200 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          disable_api_termination = true
          instance_type           = "t3.xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          description      = "RDS session host and app Server"
          update-ssm-agent = "patchgroup1"
          server-type      = "PlanetFMApp"
        })
      })

      # database servers
      pd-cafm-db-a = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.db.cloudwatch_metric_alarms,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows
        )
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "pd-cafm-db-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 500 }
          "/dev/sdc"  = { type = "gp3", size = 50 }
          "/dev/sdd"  = { type = "gp3", size = 224 }
          "/dev/sde"  = { type = "gp3", size = 500, throughput = 250 }
          "/dev/sdf"  = { type = "gp3", size = 100 }
          "/dev/sdg"  = { type = "gp3", size = 170 }                   # S: drive
          "/dev/sdh"  = { type = "gp3", size = 150 }                   # T: drive
          "/dev/sdi"  = { type = "gp3", size = 250, throughput = 250 } # U: drive
        }
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
        })
        tags = merge(local.ec2_instances.db.tags, {
          ami              = "pd-cafm-db-a"
          description      = "SQL Server"
          pre-migration    = "PDFDW0030"
          update-ssm-agent = "patchgroup1"
        })
      })

      pd-cafm-db-b = merge(local.ec2_instances.db, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.db.cloudwatch_metric_alarms,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows
        )
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "pd-cafm-db-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 500 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
          "/dev/sdd"  = { type = "gp3", size = 500 }
          "/dev/sde"  = { type = "gp3", size = 50 }
          "/dev/sdf"  = { type = "gp3", size = 85 }
          "/dev/sdg"  = { type = "gp3", size = 100 }
          "/dev/sdh"  = { type = "gp3", size = 250 } # T: drive
          "/dev/sdi"  = { type = "gp3", size = 250 } # U: drive
        }
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
          instance_type           = "r6i.4xlarge"
        })
        tags = merge(local.ec2_instances.db.tags, {
          ami              = "pd-cafm-db-b"
          description      = "SQL resilient Server"
          pre-migration    = "PDFDW0031"
          update-ssm-agent = "patchgroup2"
        })
      })

      # web servers
      pd-cafm-w-36-b = merge(local.ec2_instances.web, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.web.cloudwatch_metric_alarms,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows, {
            "cpu-utilization-high" = {
              alarm_description   = "CPU Utilization is above 75% or above for 15 minutes"
              comparison_operator = "GreaterThanOrEqualToThreshold"
              evaluation_periods  = "15"
              datapoints_to_alarm = "15"
              metric_name         = "CPUUtilization"
              namespace           = "AWS/EC2"
              period              = "60"
              statistic           = "Maximum"
              threshold           = "75"
            }
          }
        )
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pd-cafm-w-36-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          disable_api_termination = true
          instance_type           = "t3.2xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami              = "pd-cafm-w-36-b"
          description      = "CAFM Asset Management"
          pre-migration    = "PDFWW00036"
          update-ssm-agent = "patchgroup2"
        })
      })

      pd-cafm-w-37-a = merge(local.ec2_instances.web, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.web.cloudwatch_metric_alarms,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows, {
            "cpu-utilization-high" = {
              alarm_description   = "CPU Utilization is above 75% or above for 15 minutes"
              comparison_operator = "GreaterThanOrEqualToThreshold"
              evaluation_periods  = "15"
              datapoints_to_alarm = "15"
              metric_name         = "CPUUtilization"
              namespace           = "AWS/EC2"
              period              = "60"
              statistic           = "Maximum"
              threshold           = "75"
            }
          }
        )
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pd-cafm-w-37-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          disable_api_termination = true
          instance_type           = "t3.2xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami              = "pd-cafm-w-37-a"
          description      = "CAFM Assessment Management"
          pre-migration    = "PFWW00037"
          update-ssm-agent = "patchgroup1"
        })
      })

      pd-cafm-w-38-b = merge(local.ec2_instances.web, {
        cloudwatch_metric_alarms = merge(
          local.ec2_instances.web.cloudwatch_metric_alarms,
          module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows
        )
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pd-cafm-w-38-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 100 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          disable_api_termination = true
          instance_type           = "t3.large"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami              = "pd-cafm-w-38-b"
          description      = "CAFM Web Training"
          pre-migration    = "PDFWW3QCP660001"
          update-ssm-agent = "patchgroup2"
        })
      })
    }

    lbs = {
      cafmtrainweb = merge(local.lbs.web, {
        instance_target_groups = {
          cafmtrainweb-https = merge(local.lbs.web.instance_target_groups.https, {
            attachments = [
              { ec2_instance_name = "pd-cafm-w-38-b" },
            ]
          })
        }

        listeners = {
          https = merge(local.lbs.web.listeners.https, {
            default_action = {
              type              = "forward"
              target_group_name = "cafmtrainweb-https"
            }
          })
        }
      })

      cafmwebx2 = merge(local.lbs.web, {
        instance_target_groups = {
          cafmwebx2-https = merge(local.lbs.web.instance_target_groups.https, {
            attachments = [
              { ec2_instance_name = "pd-cafm-w-36-b" },
              { ec2_instance_name = "pd-cafm-w-37-a" },
            ]
          })
        }

        listeners = {
          https = merge(local.lbs.web.listeners.https, {
            alarm_target_group_names = ["cafmwebx2-https"]
            default_action = {
              type              = "forward"
              target_group_name = "cafmwebx2-https"
            }
          })
        }
      })
    }

    route53_zones = {
      "cafmtrainweb.az.justice.gov.uk" = {
        lb_alias_records = [
          { name = "", type = "A", lbs_map_key = "cafmtrainweb" },
        ]
      }
      "cafmwebx2.az.justice.gov.uk" = {
        lb_alias_records = [
          { name = "", type = "A", lbs_map_key = "cafmwebx2" },
        ]
      }
      "planetfm.service.justice.gov.uk" = {
        records = [
          { name = "_a6a2b9e651b91ed3f1e906b4f1c3c317", type = "CNAME", ttl = 86400, records = ["_c4257165635a7b495df6c4fbd986c09f.mhbtsbpdnt.acm-validations.aws"] },
          { name = "cafmtx", type = "CNAME", ttl = 3600, records = ["rdweb1.hmpps-domain.service.justice.gov.uk"] },
          { name = "pp", type = "NS", ttl = "86400", records = ["ns-1407.awsdns-47.org", "ns-1645.awsdns-13.co.uk", "ns-63.awsdns-07.com", "ns-730.awsdns-27.net"] },
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1128.awsdns-13.org", "ns-2027.awsdns-61.co.uk", "ns-854.awsdns-42.net", "ns-90.awsdns-11.com"] },
        ]
        lb_alias_records = [
          { name = "cafmtrainweb", type = "A", lbs_map_key = "cafmtrainweb" },
          { name = "cafmwebx2", type = "A", lbs_map_key = "cafmwebx2" },
        ]
      }
    }
  }
}
