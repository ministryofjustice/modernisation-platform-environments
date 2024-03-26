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
        cloudwatch_metric_alarms = local.ec2_cloudwatch_metric_alarms.database # inc. ec2_instance_cwagent_collectd_oracle_db_backup alarms
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
          pre-migration = "PPCDL00019"
          description   = "PP CSR DB server"
          ami           = "base_ol_8_5"
          os-type       = "Linux"
          component     = "test"
          server-type   = "csr-db"
          oracle-sids   = "PPIWFM"
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
          pre-migration = "PPCAW00013"
          description   = "Application Server Region 1"
          os-type       = "Windows"
          ami           = "pp-csr-a-13-a"
          component     = "app"
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
          pre-migration = "PPCAW00014"
          description   = "Application Server Region 2"
          os-type       = "Windows"
          ami           = "pp-csr-a-14-b"
          component     = "app"
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
          pre-migration = "PPCAW00017"
          description   = "Application Server Region 3"
          os-type       = "Windows"
          ami           = "pp-csr-a-17-a"
          component     = "app"
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
          pre-migration = "PPCAW00018"
          description   = "Application Server Region 4"
          os-type       = "Windows"
          ami           = "pp-csr-a-18-b"
          component     = "app"
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
          pre-migration = "PPCAW00002"
          description   = "Application Server Region 5"
          os-type       = "Windows"
          ami           = "pp-csr-a-2-b"
          component     = "app"
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
          pre-migration = "PPCAW00003"
          description   = "Application Server Region 6"
          os-type       = "Windows"
          ami           = "pp-csr-a-3-a"
          component     = "app"
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
          pre-migration = "PPCAW00015"
          description   = "Application Server Training A"
          os-type       = "Windows"
          ami           = "pp-csr-a-15-a"
          component     = "trainingA"
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
          pre-migration = "PPCAW00016"
          description   = "Application Server Training B"
          os-type       = "Windows"
          ami           = "pp-csr-a-16-b"
          component     = "trainingB"
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
          pre-migration = "PPCWW00001"
          description   = "Web Server Region 1 and 2"
          os-type       = "Windows"
          ami           = "PPCWW00001"
          component     = "web"
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
          pre-migration = "PPCWW00002"
          description   = "Web Server Region 1 and 2"
          os-type       = "Windows"
          ami           = "pp-csr-w-2-b"
          component     = "web"
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
          pre-migration = "PPCWW00005"
          description   = "Web Server Region 3 and 4"
          os-type       = "Windows"
          ami           = "PPCWW00005"
          component     = "web"
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
          pre-migration = "PPCWW00006"
          description   = "Web Server Region 3 and 4"
          os-type       = "Windows"
          ami           = "pp-csr-w-6-b"
          component     = "web"
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
          pre-migration = "PPCWW00007"
          description   = "Web Server Region 5 and 6"
          os-type       = "Windows"
          ami           = "pp-csr-w-8-b" # rebuilt using pp-csr-w-8-b AMI
          component     = "web"
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
          pre-migration = "PPCWW00008"
          description   = "Web Server Region 5 and 6"
          os-type       = "Windows"
          ami           = "pp-csr-w-8-b"
          component     = "web"
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
          pre-migration = "PPCWW00003"
          description   = "Web Server Training A and B"
          os-type       = "Windows"
          ami           = "pp-csr-w-3-a"
          component     = "trainingab"
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
          pre-migration = "PPCWW00004"
          description   = "Web Server Training A and B"
          os-type       = "Windows"
          ami           = "pp-csr-w-4-b"
          component     = "trainingab"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })
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
            port     = 7781
            protocol = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-12-7781"
            }
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
            #cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.network_lb

          }
          http-7771 = {
            alarm_target_group_names = ["pp-csr-w-34-7771"]
            port                     = 7771
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-34-7771"
            }
            # cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.network_lb
          }
          http-7780 = {
            alarm_target_group_names = ["pp-csr-w-34-7780"]
            port                     = 7780
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-34-7780"
            }
            # cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.network_lb

          }
          http-7781 = {
            alarm_target_group_names = ["pp-csr-w-34-7781"]
            port                     = 7781
            protocol                 = "TCP"
            default_action = {
              type              = "forward"
              target_group_name = "pp-csr-w-34-7781"
            }
            # cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_by_sns_topic["csr_pagerduty"].network_lb
            cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.network_lb
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



