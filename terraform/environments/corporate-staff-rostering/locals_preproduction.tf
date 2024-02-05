# csr-preproduction environment settings
locals {

  # baseline config
  preproduction_config = {

    baseline_s3_buckets = {
      csr-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
    }

    baseline_secretsmanager_secrets = {
      "/oracle/database/PPIWFM" = {
        secrets = {
          passwords = { description = "database passwords" }
        }
      }
    }

    baseline_iam_policies = {
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PP/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PP*/*",
            ]
          }
        ]
      }
    }

    baseline_ec2_instances = {
      pp-csr-db-a = merge(local.defaults_database_ec2, {
        config = merge(local.defaults_database_ec2.config, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.defaults_database_ec2.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        instance = merge(local.defaults_database_ec2.instance, {
          instance_type                = "r6i.xlarge"
          metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
          disable_api_termination      = true
          disable_api_stop             = true
        })

        ebs_volumes = merge(local.defaults_database_ec2.ebs_volumes, {
          "/dev/sda1" = { label = "root", size = 30 }
          "/dev/sdb"  = { label = "app", size = 100 } # /u01
          "/dev/sdc"  = { label = "app", size = 100 } # /u02
        })

        ebs_volume_config = merge(local.defaults_database_ec2.ebs_volume_config, {
          data = {
            iops       = 3000
            throughput = 125
            total_size = 1500
          }
          flash = {
            iops       = 3000
            throughput = 125
            total_size = 100
          }
        })

        secretsmanager_secrets = module.baseline_presets.ec2_instance.secretsmanager_secrets.oracle_19c

        tags = {
          description = "PP CSR DB server"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "csr-db"
          oracle-sids = "PPIWFM"
        }
      })

      pp-csr-a-13-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-csr-a-13-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdd"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        tags = {
          description       = "Migrated server PPCAW00013"
          app-config-status = "pending"
          csr-region        = "Region 1"
          os-type           = "Windows"
          ami               = "pp-csr-a-13-a"
          component         = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-a-14-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-csr-a-14-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 56 }
        }
        tags = {
          description       = "Migrated server PPCAW00014"
          app-config-status = "configured"
          csr-region        = "Region 2"
          os-type           = "Windows"
          ami               = "pp-csr-a-14-b"
          component         = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-a-17-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-csr-a-17-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        tags = {
          description       = "Migrated server PPCAW00017"
          app-config-status = "configured"
          csr-region        = "Region 3"
          os-type           = "Windows"
          ami               = "pp-csr-a-17-a"
          component         = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-a-18-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-csr-a-18-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 56 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        tags = {
          description       = "Migrated server PPCAW00018"
          app-config-status = "pending"
          csr-region        = "Region 4"
          os-type           = "Windows"
          ami               = "pp-csr-a-18-b"
          component         = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-a-2-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-csr-a-2-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        tags = {
          description       = "Migrated server PPCAW00002"
          app-config-status = "pending"
          csr-region        = "Region 5"
          os-type           = "Windows"
          ami               = "pp-csr-a-2-b"
          component         = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-a-3-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-csr-a-3-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        tags = {
          description       = "Migrated server PPCAW00003"
          app-config-status = "pending"
          csr-region        = "Region 6"
          os-type           = "Windows"
          ami               = "pp-csr-a-3-a"
          component         = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-a-15-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-csr-a-15-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        tags = {
          description       = "Migrated server PPCAW00015 Training Server A"
          app-config-status = "pending"
          csr-region        = "Training Server A"
          os-type           = "Windows"
          ami               = "pp-csr-a-15-a"
          component         = "trainingA"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-a-16-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pp-csr-a-16-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        tags = {
          description       = "Migrated server PPCAW00016 Training Server B"
          app-config-status = "pending"
          csr-region        = "Training Server B"
          os-type           = "Windows"
          ami               = "pp-csr-a-16-b"
          component         = "trainingB"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-w-1-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "PPCWW00001"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 129 }
          "/dev/sdd"  = { type = "gp3", size = 129 }
        }
        tags = {
          description       = "Migrated server PPCWW00001"
          app-config-status = "pending"
          csr-region        = "Region 1 and 2"
          os-type           = "Windows"
          ami               = "PPCWW00001"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-w-2-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-csr-w-2-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 129 }
          "/dev/sdc"  = { type = "gp3", size = 56 }
          "/dev/sdd"  = { type = "gp3", size = 129 }
        }
        tags = {
          description       = "Migrated server PPCWW00002"
          app-config-status = "configured"
          csr-region        = "Region 1 and 2"
          os-type           = "Windows"
          ami               = "pp-csr-w-2-b"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-w-5-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "PPCWW00005"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 129 }
        }
        tags = {
          description       = "Migrated server PPCWW00005"
          app-config-status = "configured"
          csr-region        = "Region 3 and 4"
          os-type           = "Windows"
          ami               = "PPCWW00005"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-w-6-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-csr-w-6-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 129 }
          "/dev/sdd"  = { type = "gp3", size = 129 }
        }
        tags = {
          description       = "Migrated server PPCWW00006"
          app-config-status = "pending"
          csr-region        = "Region 3 and 4"
          os-type           = "Windows"
          ami               = "pp-csr-w-6-b"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-w-7-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-csr-w-8-b"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 200 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        tags = {
          description       = "Rebuild of PP-csr-w-7-a using pp-csr-w-8-b ami "
          app-config-status = "pending"
          csr-region        = "Region 5 and 6"
          os-type           = "Windows"
          ami               = "pp-csr-w-8-b"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-w-8-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-csr-w-8-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 200 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
        }
        tags = {
          description       = "Migrated server PPCWW00008"
          app-config-status = "pending"
          csr-region        = "Region 5 and 6"
          os-type           = "Windows"
          ami               = "pp-csr-w-8-b"
          component         = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-w-3-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-csr-w-3-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 129 }
          "/dev/sdc"  = { type = "gp3", size = 129 }
          "/dev/sdd"  = { type = "gp3", size = 56 }
        }
        tags = {
          description       = "Migrated server PPCWW00003"
          app-config-status = "pending"
          csr-region        = "Training Server A and B"
          os-type           = "Windows"
          ami               = "pp-csr-w-3-a"
          component         = "trainingab"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pp-csr-w-4-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pp-csr-w-4-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.2xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 56 }
          "/dev/sdc"  = { type = "gp3", size = 129 }
          "/dev/sdd"  = { type = "gp3", size = 129 }
        }
        tags = {
          description       = "Migrated server PPCWW00004"
          app-config-status = "pending"
          csr-region        = "Training Server A and B"
          os-type           = "Windows"
          ami               = "pp-csr-w-4-b"
          component         = "trainingab"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

    }

    baseline_ec2_autoscaling_groups = {
      pp-web-tst-1 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-*" # Microsoft Windows Server 2022 Base
          ami_owner                     = "754260907303"
          ebs_volumes_copy_all_from_ami = false
          instance_profile_policies     = concat(module.baseline_presets.ec2_instance.config.default.instance_profile_policies, ["CSRWebServerPolicy"])
        })

        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["web", "domain", "jumpserver"]
          instance_type          = "t3.medium"

        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 256 }
        }
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0 # set to 0 while testing
        })
        tags = {
          description = "Test Windows Web Server 2019"
          os-type     = "Windows"
          component   = "Test"
          server-type = "test-windows-server"
        }
      }
    }

    baseline_lbs = {
      r12 = {
        internal_lb              = true
        enable_delete_protection = false
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
          pp-csr-w-12-80 = {
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
              { ec2_instance_name = "pp-csr-w-1-a" },
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          }
          pp-csr-w-12-7770 = {
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
              { ec2_instance_name = "pp-csr-w-1-a" },
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          }
          pp-csr-w-12-7771 = {
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
              { ec2_instance_name = "pp-csr-w-1-a" },
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          }
          pp-csr-w-12-7780 = {
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
              { ec2_instance_name = "pp-csr-w-1-a" },
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          }
          pp-csr-w-12-7781 = {
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
              { ec2_instance_name = "pp-csr-w-1-a" },
              { ec2_instance_name = "pp-csr-w-2-b" },
            ]
          }
        }

        listeners = {

          http = {
            port     = 80
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-12-80"
            }
          }
          http-7770 = {
            port     = 7770
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-12-7770"
            }
          }
          http-7771 = {

            port     = 7771
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-12-7771"
            }
          }
          http-7780 = {
            port     = 7780
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-12-7780"
            }
          }
          http-7781 = {
            alarm_target_group_names = ["pp-csr-w-12-7781"] # this alarm will deliberately fail, will be removed later
            port                     = 7781
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-12-7781"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
        }
      }
      r34 = {
        internal_lb              = true
        enable_delete_protection = false
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
          pp-csr-w-56-80 = {
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
              { ec2_instance_name = "pp-csr-w-5-a" },
              { ec2_instance_name = "pp-csr-w-6-b" },
            ]
          }
          pp-csr-w-56-7770 = {
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
              { ec2_instance_name = "pp-csr-w-5-a" },
              { ec2_instance_name = "pp-csr-w-6-b" },
            ]
          }
          pp-csr-w-56-7771 = {
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
              { ec2_instance_name = "pp-csr-w-5-a" },
              { ec2_instance_name = "pp-csr-w-6-b" },
            ]
          }
          pp-csr-w-56-7780 = {
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
              { ec2_instance_name = "pp-csr-w-5-a" },
              { ec2_instance_name = "pp-csr-w-6-b" },
            ]
          }
          pp-csr-w-56-7781 = {
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
              { ec2_instance_name = "pp-csr-w-5-a" },
              { ec2_instance_name = "pp-csr-w-6-b" },
            ]
          }
        }

        listeners = {
          http = {
            port     = 80
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-56-80"
            }
          }
          http-7770 = {
            port     = 7770
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-56-7770"
            }
          }
          http-7771 = {
            port     = 7771
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-56-7771"
            }
          }
          http-7780 = {
            port     = 7780
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-56-7780"
            }
          }
          http-7781 = {
            port     = 7781
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-56-7781"
            }
          }
        }
      }
      r56 = {
        internal_lb              = true
        enable_delete_protection = false
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
          pp-csr-w-78-80 = {
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
              { ec2_instance_name = "pp-csr-w-7-a" },
              { ec2_instance_name = "pp-csr-w-8-b" },
            ]
          }
          pp-csr-w-78-7770 = {
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
              { ec2_instance_name = "pp-csr-w-7-a" },
              { ec2_instance_name = "pp-csr-w-8-b" },
            ]
          }
          pp-csr-w-78-7771 = {
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
              { ec2_instance_name = "pp-csr-w-7-a" },
              { ec2_instance_name = "pp-csr-w-8-b" },
            ]
          }
          pp-csr-w-78-7780 = {
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
              { ec2_instance_name = "pp-csr-w-7-a" },
              { ec2_instance_name = "pp-csr-w-8-b" },
            ]
          }
          pp-csr-w-78-7781 = {
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
              { ec2_instance_name = "pp-csr-w-7-a" },
              { ec2_instance_name = "pp-csr-w-8-b" },
            ]
          }
        }

        listeners = {
          http = {
            port     = 80
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-78-80"
            }
          }
          http-7770 = {
            port     = 7770
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-78-7770"
            }
          }
          http-7771 = {
            port     = 7771
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-78-7771"
            }
          }
          http-7780 = {
            port     = 7780
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-78-7780"
            }
          }
          http-7781 = {
            port     = 7781
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-78-7781"
            }
          }
        }
      }
      trainab = {
        internal_lb              = true
        enable_delete_protection = false
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
          pp-csr-w-34-80 = {
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
              { ec2_instance_name = "pp-csr-w-3-a" },
              { ec2_instance_name = "pp-csr-w-4-b" },
            ]
          }
          pp-csr-w-34-7770 = {
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
              { ec2_instance_name = "pp-csr-w-3-a" },
              { ec2_instance_name = "pp-csr-w-4-b" },
            ]
          }
          pp-csr-w-34-7771 = {
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
              { ec2_instance_name = "pp-csr-w-3-a" },
              { ec2_instance_name = "pp-csr-w-4-b" },
            ]
          }
          pp-csr-w-34-7780 = {
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
              { ec2_instance_name = "pp-csr-w-3-a" },
              { ec2_instance_name = "pp-csr-w-4-b" },
            ]
          }
          pp-csr-w-34-7781 = {
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
              { ec2_instance_name = "pp-csr-w-3-a" },
              { ec2_instance_name = "pp-csr-w-4-b" },
            ]
          }
        }

        listeners = {
          http = {
            port     = 80
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-34-80"
            }
          }
          http-7770 = {
            alarm_target_group_names = ["pp-csr-w-34-7770"]
            port                     = 7770
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-34-7770"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
          http-7771 = {
            alarm_target_group_names = ["pp-csr-w-34-7771"]
            port                     = 7771
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-34-7771"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
          http-7780 = {
            alarm_target_group_names = ["pp-csr-w-34-7780"]
            port                     = 7780
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-34-7780"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
          http-7781 = {
            alarm_target_group_names = ["pp-csr-w-34-7781"]
            port                     = 7781
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-34-7781"
            }
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
          }
        }
      }
    }

    baseline_route53_zones = {
      "pp.csr.service.justice.gov.uk" = {
        records = [
          # Set to IP of the Azure CSR PP DB in PPCDL00019
          { name = "ppiwfm", type = "A", ttl = "300", records = ["10.40.42.132"] },
          { name = "ppiwfm-a", type = "A", ttl = "300", records = ["10.40.42.132"] },
          { name = "ppiwfm-b", type = "CNAME", ttl = "300", records = ["pp-csr-db-a.corporate-staff-rostering.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
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
  }
}



