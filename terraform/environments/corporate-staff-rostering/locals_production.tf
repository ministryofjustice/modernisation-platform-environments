locals {

  baseline_presets_production = {
    options = {
      db_backup_lifecycle_rule = "rman_backup_one_month"
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {

    ec2_instances = {
      pd-csr-db-a = merge(local.defaults_database_ec2, {
        config = merge(local.defaults_database_ec2.config, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.defaults_database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.defaults_database_ec2.ebs_volumes, {
          "/dev/sda1" = { label = "root", size = 30 }
          "/dev/sdb"  = { label = "app", size = 100 } # /u01
          "/dev/sdc"  = { label = "app", size = 500 } # /u02
        })
        ebs_volume_config = merge(local.defaults_database_ec2.ebs_volume_config, {
          data  = { total_size = 1500 }
          flash = { total_size = 500 }
        })
        instance = merge(local.defaults_database_ec2.instance, {
        })
        tags = merge(local.defaults_database_ec2.tags, {
          pre-migration = "PDCDL00013"
          description   = "PD CSR Oracle primary DB server"
          ami           = "base_ol_8_5"
        })
      })

      pd-csr-db-b = merge(local.defaults_database_ec2, {
        config = merge(local.defaults_database_ec2.config, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          availability_zone = "eu-west-2b"
          instance_profile_policies = concat(local.defaults_database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.defaults_database_ec2.ebs_volumes, {
          "/dev/sda1" = { label = "root", size = 30 }
          "/dev/sdb"  = { label = "app", size = 100 } # /u01
          "/dev/sdc"  = { label = "app", size = 500 } # /u02
        })
        ebs_volume_config = merge(local.defaults_database_ec2.ebs_volume_config, {
          data  = { total_size = 1500 }
          flash = { total_size = 500 }
        })
        instance = merge(local.defaults_database_ec2.instance, {
        })
        tags = merge(local.defaults_database_ec2.tags, {
          pre-migration = "PDCDL00014"
          description   = "PD CSR Oracle secondary DB server"
          ami           = "base_ol_8_5"
          backup        = "false" # opt out of mod platform default backup plan
        })
      })

      pd-csr-a-7-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-csr-a-7-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.defaults_app_ec2.tags, {
          pre-migration = "PDCAW00007"
          description   = "Application Server Region 1"
          ami           = "pd-csr-a-7-a"
        })
      })

      pd-csr-a-8-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-csr-a-8-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.defaults_app_ec2.tags, {
          pre-migration = "PDCAW00008"
          description   = "Application Server Region 2"
          ami           = "pd-csr-a-8-b"
        })
      })

      pd-csr-a-9-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-csr-a-9-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.defaults_app_ec2.tags, {
          pre-migration = "PDCAW00009"
          description   = "Application Server Region 3"
          ami           = "pd-csr-a-9-a"
        })
      })

      pd-csr-a-10-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-csr-a-10-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.defaults_app_ec2.tags, {
          pre-migration = "PDCAW00010"
          description   = "Application Server Region 4"
          ami           = "pd-csr-a-10-b"
        })
      })

      pd-csr-a-11-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-csr-a-11-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 112 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.defaults_app_ec2.tags, {
          pre-migration = "PDCAW00011"
          description   = "Application Server Region 5"
          ami           = "pd-csr-a-11-a"
        })
      })

      pd-csr-a-12-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-csr-a-12-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.defaults_app_ec2.tags, {
          pre-migration = "PDCAW00012"
          description   = "Application Server Region 6"
          ami           = "pd-csr-a-12-b"
        })
      })

      pd-csr-w-1-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-csr-w-1-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.defaults_web_ec2.tags, {
          pre-migration = "PDCWW00001"
          description   = "Web Server Region 1 and 2"
          ami           = "pd-csr-w-1-a"
        })
      })

      pd-csr-w-2-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-csr-w-2-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.defaults_web_ec2.tags, {
          pre-migration = "PDCWW00002"
          description   = "Web Server Region 1 and 2"
          ami           = "pd-csr-w-2-b"
        })
      })

      pd-csr-w-3-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-csr-w-3-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.defaults_web_ec2.tags, {
          pre-migration = "PDCWW00003"
          description   = "Web Server Region 3 and 4"
          ami           = "pd-csr-w-3-a"
        })
      })

      pd-csr-w-4-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-csr-w-4-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 112 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.defaults_web_ec2.tags, {
          pre-migration = "PDCWW00004"
          description   = "Web Server Region 3 and 4"
          ami           = "pd-csr-w-4-b"
        })
      })

      pd-csr-w-5-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-csr-w-5-a"
          availability_zone = "eu-west-2a"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.defaults_web_ec2.tags, {
          pre-migration = "PDCWW00005"
          description   = "Web Server Region 5 and 6"
          ami           = "pd-csr-w-5-a"
        })
      })

      pd-csr-w-6-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-csr-w-6-b"
          availability_zone = "eu-west-2b"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        tags = merge(local.defaults_web_ec2.tags, {
          pre-migration = "PDCWW00006"
          description   = "Web Server Region 5 and 6"
          ami           = "pd-csr-w-6-b"
        })
      })
    }

    iam_policies = {
      Ec2ProdDatabasePolicy = {
        description = "Permissions required for prod Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "ssm:GetParameter",
            ]
            resources = [
              "arn:aws:ssm:*:*:parameter/azure/*",
            ]
          },
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*P/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/P*/*",
            ]
          }
        ]
      }
    }

    lbs = {
      r12 = {
        internal_lb              = true
        enable_delete_protection = true
        load_balancer_type       = "network"
        force_destroy_bucket     = true
        subnets = [
          module.environment.subnet["private"]["eu-west-2a"].id,
          module.environment.subnet["private"]["eu-west-2b"].id,
        ]
        security_groups                  = ["load-balancer"]
        access_logs                      = false
        enable_cross_zone_load_balancing = true

        instance_target_groups = {
          pd-csr-w-12-80 = {
            port     = 80
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              port                = 80
              protocol            = "TCP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-1-a" },
              { ec2_instance_name = "pd-csr-w-2-b" },
            ]
          }
          pd-csr-w-12-7770 = {
            port     = 7770
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/isps/index.html"
              port                = 7770
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-1-a" },
              { ec2_instance_name = "pd-csr-w-2-b" },
            ]
          }
          pd-csr-w-12-7771 = {
            port     = 7771
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/isps/index.html"
              port                = 7771
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-1-a" },
              { ec2_instance_name = "pd-csr-w-2-b" },
            ]
          }
          pd-csr-w-12-7780 = {
            port     = 7780
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/"
              port                = 7770
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-1-a" },
              { ec2_instance_name = "pd-csr-w-2-b" },
            ]
          }
          pd-csr-w-12-7781 = {
            port     = 7781
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/"
              port                = 7771
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-1-a" },
              { ec2_instance_name = "pd-csr-w-2-b" },
            ]
          }
        }

        listeners = {
          http = {

            port     = 80
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-12-80"
            }
          }
          http-7770 = {
            alarm_target_group_names = ["pd-csr-w-12-7770"]
            port                     = 7770
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-12-7770"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
          http-7771 = {
            alarm_target_group_names = ["pd-csr-w-12-7771"]
            port                     = 7771
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-12-7771"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
          http-7780 = {
            alarm_target_group_names = ["pd-csr-w-12-7780"]
            port                     = 7780
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-12-7780"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
          http-7781 = {
            alarm_target_group_names = ["pd-csr-w-12-7781"]
            port                     = 7781
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-12-7781"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
        }
      }
      r34 = {
        internal_lb              = true
        enable_delete_protection = true
        load_balancer_type       = "network"
        force_destroy_bucket     = true
        subnets = [
          module.environment.subnet["private"]["eu-west-2a"].id,
          module.environment.subnet["private"]["eu-west-2b"].id,
        ]
        security_groups                  = ["load-balancer"]
        access_logs                      = false
        enable_cross_zone_load_balancing = true

        instance_target_groups = {
          pd-csr-w-34-80 = {
            port     = 80
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              port                = 80
              protocol            = "TCP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-3-a" },
              { ec2_instance_name = "pd-csr-w-4-b" },
            ]
          }
          pd-csr-w-34-7770 = {
            port     = 7770
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/isps/index.html"
              port                = 7770
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-3-a" },
              { ec2_instance_name = "pd-csr-w-4-b" },
            ]
          }
          pd-csr-w-34-7771 = {
            port     = 7771
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/isps/index.html"
              port                = 7771
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-3-a" },
              { ec2_instance_name = "pd-csr-w-4-b" },
            ]
          }
          pd-csr-w-34-7780 = {
            port     = 7780
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/"
              port                = 7770
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-3-a" },
              { ec2_instance_name = "pd-csr-w-4-b" },
            ]
          }
          pd-csr-w-34-7781 = {
            port     = 7781
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/"
              port                = 7771
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-3-a" },
              { ec2_instance_name = "pd-csr-w-4-b" },
            ]
          }
        }

        listeners = {
          http = {
            port     = 80
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-34-80"
            }
          }
          http-7770 = {
            alarm_target_group_names = ["pd-csr-w-34-7770"]
            port                     = 7770
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-34-7770"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
          http-7771 = {
            alarm_target_group_names = ["pd-csr-w-34-7771"]
            port                     = 7771
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-34-7771"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
          http-7780 = {
            alarm_target_group_names = ["pd-csr-w-34-7780"]
            port                     = 7780
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-34-7780"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
          http-7781 = {
            alarm_target_group_names = ["pd-csr-w-34-7781"]
            port                     = 7781
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-34-7781"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
        }
      }
      r56 = {
        internal_lb              = true
        enable_delete_protection = true
        load_balancer_type       = "network"
        force_destroy_bucket     = true
        subnets = [
          module.environment.subnet["private"]["eu-west-2a"].id,
          module.environment.subnet["private"]["eu-west-2b"].id,
        ]
        security_groups                  = ["load-balancer"]
        access_logs                      = false
        enable_cross_zone_load_balancing = true

        instance_target_groups = {
          pd-csr-w-56-80 = {
            port     = 80
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              port                = 80
              protocol            = "TCP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-5-a" },
              { ec2_instance_name = "pd-csr-w-6-b" },
            ]
          }
          pd-csr-w-56-7770 = {
            port     = 7770
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/isps/index.html"
              port                = 7770
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-5-a" },
              { ec2_instance_name = "pd-csr-w-6-b" },
            ]
          }
          pd-csr-w-56-7771 = {
            port     = 7771
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/isps/index.html"
              port                = 7771
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-5-a" },
              { ec2_instance_name = "pd-csr-w-6-b" },
            ]
          }
          pd-csr-w-56-7780 = {
            port     = 7780
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/"
              port                = 7770
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-5-a" },
              { ec2_instance_name = "pd-csr-w-6-b" },
            ]
          }
          pd-csr-w-56-7781 = {
            port     = 7781
            protocol = "TCP"
            health_check = {
              enabled             = true
              interval            = 5
              healthy_threshold   = 3
              path                = "/"
              port                = 7771
              protocol            = "HTTP"
              timeout             = 4
              unhealthy_threshold = 2
            }
            stickiness = {
              enabled = true
              type    = "source_ip"
            }
            attachments = [
              { ec2_instance_name = "pd-csr-w-5-a" },
              { ec2_instance_name = "pd-csr-w-6-b" },
            ]
          }
        }

        listeners = {
          http = {
            port     = 80
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-56-80"
            }
          }
          http-7770 = {
            alarm_target_group_names = ["pd-csr-w-56-7770"]
            port                     = 7770
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-56-7770"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
          http-7771 = {
            alarm_target_group_names = ["pd-csr-w-56-7771"]
            port                     = 7771
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-56-7771"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
          http-7780 = {
            alarm_target_group_names = ["pd-csr-w-56-7780"]
            port                     = 7780
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-56-7780"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
          http-7781 = {
            alarm_target_group_names = ["pd-csr-w-56-7781"]
            port                     = 7781
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pd-csr-w-56-7781"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
        }
      }
    }

    route53_zones = {
      "csr.service.justice.gov.uk" = {

        records = [
          { name = "test", type = "NS", ttl = "86400", records = ["ns-1332.awsdns-38.org", "ns-2038.awsdns-62.co.uk", "ns-62.awsdns-07.com", "ns-689.awsdns-22.net"] },
          { name = "pp", type = "NS", ttl = "86400", records = ["ns-1408.awsdns-48.org", "ns-1844.awsdns-38.co.uk", "ns-447.awsdns-55.com", "ns-542.awsdns-03.net"] },
          { name = "piwfm", type = "A", ttl = "300", records = ["10.40.8.132"] },
          { name = "traina", type = "CNAME", ttl = "300", records = ["traina.pp.csr.service.justice.gov.uk"] },
          { name = "trainb", type = "CNAME", ttl = "300", records = ["trainb.pp.csr.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "r1", type = "A", lbs_map_key = "r12" },
          { name = "r2", type = "A", lbs_map_key = "r12" },
          { name = "r3", type = "A", lbs_map_key = "r34" },
          { name = "r4", type = "A", lbs_map_key = "r34" },
          { name = "r5", type = "A", lbs_map_key = "r56" },
          { name = "r6", type = "A", lbs_map_key = "r56" },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/database/PIWFM" = {
        secrets = {
          passwords = { description = "database passwords" }
        }
      }
      "/oracle/database/DIWFM" = {
        secrets = {
          passwords = { description = "database passwords" }
        }
      }
    }
  }
}
