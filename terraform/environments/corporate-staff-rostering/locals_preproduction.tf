locals {

  baseline_presets_preproduction = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "corporate-staff-rostering-preproduction"
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
          local.cloudwatch_dashboard_widget_groups.all_ec2,
          local.cloudwatch_dashboard_widget_groups.db,
          local.cloudwatch_dashboard_widget_groups.app,
          local.cloudwatch_dashboard_widget_groups.web,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
        ]
      }
    }

    ec2_instances = {
      pp-csr-db-a = merge(local.ec2_instances.db, {
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sda1" = { label = "root", size = 30 }
          "/dev/sdb"  = { label = "app", size = 200 } # /u01
          "/dev/sdc"  = { label = "app", size = 100 } # /u02
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 1500 }
          flash = { total_size = 100 }
        })
        instance = merge(local.ec2_instances.db.instance, {
        })
        tags = merge(local.ec2_instances.db.tags, {
          description         = "PP CSR DB server"
          instance-scheduling = "skip-scheduling"
          oracle-sids         = "PPIWFM"
          pre-migration       = "PPCDL00019"
          server-type         = "csr-db"
        })
      })

      pp-csr-a-13-a = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pp-csr-a-13-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdd"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami                 = "pp-csr-a-13-a"
          description         = "Application Server Region 1"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCAW00013"
        })
      })

      pp-csr-a-14-b = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pp-csr-a-14-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 56 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami                 = "pp-csr-a-14-b"
          description         = "Application Server Region 2"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCAW00014"
        })
      })

      pp-csr-a-17-a = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pp-csr-a-17-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami                 = "pp-csr-a-17-a"
          description         = "Application Server Region 3"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCAW00017"
        })
      })

      pp-csr-a-18-b = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pp-csr-a-18-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 56 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami                 = "pp-csr-a-18-b"
          description         = "Application Server Region 4"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCAW00018"
        })
      })

      pp-csr-a-2-b = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pp-csr-a-2-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami                 = "pp-csr-a-2-b"
          description         = "Application Server Region 5"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCAW00002"
        })
      })

      pp-csr-a-3-a = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pp-csr-a-3-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami                 = "pp-csr-a-3-a"
          description         = "Application Server Region 6"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCAW00003"
        })
      })

      pp-csr-a-15-a = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pp-csr-a-15-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami                 = "pp-csr-a-15-a"
          description         = "Application Server Training A"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCAW00015"
        })
      })

      pp-csr-a-16-b = merge(local.ec2_instances.app, {
        config = merge(local.ec2_instances.app.config, {
          ami_name          = "pp-csr-a-16-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.ec2_instances.app.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.app.tags, {
          ami                 = "pp-csr-a-16-b"
          description         = "Application Server Training B"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCAW00016"
        })
      })

      pp-csr-w-1-a = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "PPCWW00001"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 129 }
          "/dev/sdd"  = { type = "gp3", size = 129 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami                 = "PPCWW00001"
          description         = "Web Server Region 1 and 2"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCWW00001"
        })
      })

      pp-csr-w-2-b = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pp-csr-w-2-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 129 }
          "/dev/sdc"  = { type = "gp3", size = 56 }
          "/dev/sdd"  = { type = "gp3", size = 129 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami                 = "pp-csr-w-2-b"
          description         = "Web Server Region 1 and 2"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCWW00002"
        })
      })

      pp-csr-w-5-a = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "PPCWW00005"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 129 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami                 = "PPCWW00005"
          description         = "Web Server Region 3 and 4"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCWW00005"
        })
      })

      pp-csr-w-6-b = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pp-csr-w-6-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 129 }
          "/dev/sdd"  = { type = "gp3", size = 129 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami                 = "pp-csr-w-6-b"
          description         = "Web Server Region 3 and 4"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCWW00006"
        })
      })

      pp-csr-w-7-a = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pp-csr-w-8-b"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 200 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami                 = "pp-csr-w-8-b" # rebuilt using pp-csr-w-8-b AMI
          description         = "Web Server Region 5 and 6"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCWW00007"
        })
      })

      pp-csr-w-8-b = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pp-csr-w-8-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 200 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami                 = "pp-csr-w-8-b"
          description         = "Web Server Region 5 and 6"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCWW00008"
        })
      })

      pp-csr-w-3-a = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pp-csr-w-3-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 129 }
          "/dev/sdc"  = { type = "gp3", size = 129 }
          "/dev/sdd"  = { type = "gp3", size = 56 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami                 = "pp-csr-w-3-a"
          description         = "Web Server Training A and B"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCWW00003"
        })
      })

      pp-csr-w-4-b = merge(local.ec2_instances.web, {
        config = merge(local.ec2_instances.web.config, {
          ami_name          = "pp-csr-w-4-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 129 }
          "/dev/sdd"  = { type = "gp3", size = 129 }
        }
        instance = merge(local.ec2_instances.web.instance, {
          instance_type = "m5.2xlarge"
        })
        tags = merge(local.ec2_instances.web.tags, {
          ami                 = "pp-csr-w-4-b"
          description         = "Web Server Training A and B"
          instance-scheduling = "skip-scheduling"
          pre-migration       = "PPCWW00004"
        })
      })
    }

    iam_policies = {
      Ec2PreprodDatabasePolicy = {
        description = "Permissions required for Preprod Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "s3:GetBucketLocation",
              "s3:GetObject",
              "s3:GetObjectTagging",
              "s3:ListBucket",
            ]
            resources = [
              "arn:aws:s3:::csr-db-backup-bucket*",
            ]
          },
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PP/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PP*/*",
            ]
          }
        ]
      }
    }

    lbs = {
      r12 = merge(local.lbs.rxy, {
        instance_target_groups = {
          pp-csr-w-12-80 = merge(local.lbs.rxy.instance_target_groups.w-80, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-1-a" },
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          })
          pp-csr-w-12-7770 = merge(local.lbs.rxy.instance_target_groups.w-7770, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-1-a" },
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          })
          pp-csr-w-12-7771 = merge(local.lbs.rxy.instance_target_groups.w-7771, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-1-a" },
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          })
          pp-csr-w-12-7780 = merge(local.lbs.rxy.instance_target_groups.w-7780, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-1-a" },
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          })
          pp-csr-w-12-7781 = merge(local.lbs.rxy.instance_target_groups.w-7781, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-1-a" },
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          })
        }

        listeners = {
          http = merge(local.lbs.rxy.listeners.http, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-12-80"
            }
          })
          http-7770 = merge(local.lbs.rxy.listeners.http-7770, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-12-7770"
            }
          })
          http-7771 = merge(local.lbs.rxy.listeners.http-7771, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-12-7771"
            }
          })
          http-7780 = merge(local.lbs.rxy.listeners.http-7780, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-12-7780"
            }
          })
          http-7781 = merge(local.lbs.rxy.listeners.http-7781, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-12-7781"
            }
          })
        }
      })

      r34 = merge(local.lbs.rxy, {
        instance_target_groups = {
          pp-csr-w-56-80 = merge(local.lbs.rxy.instance_target_groups.w-80, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-5-a" },
              { ec2_instance_name = "pp-csr-w-6-b" },
            ]
          })
          pp-csr-w-56-7770 = merge(local.lbs.rxy.instance_target_groups.w-7770, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-5-a" },
              { ec2_instance_name = "pp-csr-w-6-b" },
            ]
          })
          pp-csr-w-56-7771 = merge(local.lbs.rxy.instance_target_groups.w-7771, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-5-a" },
              { ec2_instance_name = "pp-csr-w-6-b" },
            ]
          })
          pp-csr-w-56-7780 = merge(local.lbs.rxy.instance_target_groups.w-7780, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-5-a" },
              { ec2_instance_name = "pp-csr-w-6-b" },
            ]
          })
          pp-csr-w-56-7781 = merge(local.lbs.rxy.instance_target_groups.w-7781, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-5-a" },
              { ec2_instance_name = "pp-csr-w-6-b" },
            ]
          })
        }

        listeners = {
          http = merge(local.lbs.rxy.listeners.http, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-56-80"
            }
          })
          http-7770 = merge(local.lbs.rxy.listeners.http-7770, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-56-7770"
            }
          })
          http-7771 = merge(local.lbs.rxy.listeners.http-7771, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-56-7771"
            }
          })
          http-7780 = merge(local.lbs.rxy.listeners.http-7780, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-56-7780"
            }
          })
          http-7781 = merge(local.lbs.rxy.listeners.http-7781, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-56-7781"
            }
          })
        }
      })

      r56 = merge(local.lbs.rxy, {
        instance_target_groups = {
          pp-csr-w-78-80 = merge(local.lbs.rxy.instance_target_groups.w-80, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-7-a" },
              { ec2_instance_name = "pp-csr-w-8-b" },
            ]
          })
          pp-csr-w-78-7770 = merge(local.lbs.rxy.instance_target_groups.w-7770, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-7-a" },
              { ec2_instance_name = "pp-csr-w-8-b" },
            ]
          })
          pp-csr-w-78-7771 = merge(local.lbs.rxy.instance_target_groups.w-7771, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-7-a" },
              { ec2_instance_name = "pp-csr-w-8-b" },
            ]
          })
          pp-csr-w-78-7780 = merge(local.lbs.rxy.instance_target_groups.w-7780, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-7-a" },
              { ec2_instance_name = "pp-csr-w-8-b" },
            ]
          })
          pp-csr-w-78-7781 = merge(local.lbs.rxy.instance_target_groups.w-7781, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-7-a" },
              { ec2_instance_name = "pp-csr-w-8-b" },
            ]
          })
        }

        listeners = {
          http = merge(local.lbs.rxy.listeners.http, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-78-80"
            }
          })
          http-7770 = merge(local.lbs.rxy.listeners.http-7770, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-78-7770"
            }
          })
          http-7771 = merge(local.lbs.rxy.listeners.http-7771, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-78-7771"
            }
          })
          http-7780 = merge(local.lbs.rxy.listeners.http-7780, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-78-7780"
            }
          })
          http-7781 = merge(local.lbs.rxy.listeners.http-7781, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-78-7781"
            }
          })
        }
      })

      trainab = merge(local.lbs.rxy, {
        instance_target_groups = {
          pp-csr-w-34-80 = merge(local.lbs.rxy.instance_target_groups.w-80, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-3-a" },
              { ec2_instance_name = "pp-csr-w-4-b" },
            ]
          })
          pp-csr-w-34-7770 = merge(local.lbs.rxy.instance_target_groups.w-7770, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-3-a" },
              { ec2_instance_name = "pp-csr-w-4-b" },
            ]
          })
          pp-csr-w-34-7771 = merge(local.lbs.rxy.instance_target_groups.w-7771, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-3-a" },
              { ec2_instance_name = "pp-csr-w-4-b" },
            ]
          })
          pp-csr-w-34-7780 = merge(local.lbs.rxy.instance_target_groups.w-7780, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-3-a" },
              { ec2_instance_name = "pp-csr-w-4-b" },
            ]
          })
          pp-csr-w-34-7781 = merge(local.lbs.rxy.instance_target_groups.w-7781, {
            attachments = [
              { ec2_instance_name = "pp-csr-w-3-a" },
              { ec2_instance_name = "pp-csr-w-4-b" },
            ]
          })
        }

        listeners = {
          http = merge(local.lbs.rxy.listeners.http, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-34-80"
            }
          })
          http-7770 = merge(local.lbs.rxy.listeners.http-7770, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-34-7770"
            }
          })
          http-7771 = merge(local.lbs.rxy.listeners.http-7771, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-34-7771"
            }
          })
          http-7780 = merge(local.lbs.rxy.listeners.http-7780, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-34-7780"
            }
          })
          http-7781 = merge(local.lbs.rxy.listeners.http-7781, {
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-34-7781"
            }
          })
        }
      })
    }

    route53_zones = {
      "pp.csr.service.justice.gov.uk" = {
        records = [
          { name = "ppiwfm", type = "CNAME", ttl = "300", records = ["pp-csr-db-a.corporate-staff-rostering.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "r1", type = "A", lbs_map_key = "r12" },
          { name = "r2", type = "A", lbs_map_key = "r12" },
          { name = "r3", type = "A", lbs_map_key = "r34" },
          { name = "r4", type = "A", lbs_map_key = "r34" },
          { name = "r5", type = "A", lbs_map_key = "r56" },
          { name = "r6", type = "A", lbs_map_key = "r56" },
          { name = "traina", type = "A", lbs_map_key = "trainab" },
          { name = "trainb", type = "A", lbs_map_key = "trainab" },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/database/PPIWFM" = {
        secrets = {
          passwords = { description = "database passwords" }
        }
      }
    }
  }
}
