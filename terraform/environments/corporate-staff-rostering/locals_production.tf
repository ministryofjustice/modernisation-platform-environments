# csr-production environment settings
locals {

  # baseline config
  production_config = {

    baseline_s3_buckets = {
      csr-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ProdPreprodEnvironmentsReadOnlyAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }

    baseline_secretsmanager_secrets = {
      "/oracle/database/PIWFM" = {
        secrets = {
          passwords = { description = "database passwords" }
        }
      }
      "/oracle/database/DRIWFM" = {
        secrets = {
          passwords = { description = "database passwords" }
        }
      }
    }

    baseline_iam_policies = {
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

    baseline_ec2_instances = {
      pd-csr-db-a = merge(local.defaults_database_ec2, {
        config = merge(local.defaults_database_ec2.config, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          availability_zone = "${local.region}a"
          instance_profile_policies = concat(local.defaults_database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        instance = merge(local.defaults_database_ec2.instance, {
          instance_type                = "r6i.xlarge"
          metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
          disable_api_stop             = false
          tags = merge(local.defaults_database_ec2.instance.tags, {
            instance-scheduling = null
          })
        })

        ebs_volumes = merge(local.defaults_database_ec2.ebs_volumes, {
          "/dev/sda1" = { label = "root", size = 30 }
          "/dev/sdb"  = { label = "app", size = 100 } # /u01
          "/dev/sdc"  = { label = "app", size = 500 } # /u02
        })

        ebs_volume_config = merge(local.defaults_database_ec2.ebs_volume_config, {
          data = {
            total_size = 1500
          }
          flash = {
            total_size = 100
          }
        })

        secretsmanager_secrets = module.baseline_presets.ec2_instance.secretsmanager_secrets.oracle_19c

        tags = {
          pre-migration = "PDCDL00013"
          description   = "PD CSR Oracle primary DB server"
          ami           = "base_ol_8_5"
          os-type       = "Linux"
          component     = "data"
          server-type   = "csr-db"
          backup        = "false" # opt out of mod platform default backup plan
        }
      })

      pd-csr-db-b = merge(local.defaults_database_ec2, {
        config = merge(local.defaults_database_ec2.config, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-07-14T15-36-30.795Z"
          availability_zone = "${local.region}b"
          instance_profile_policies = concat(local.defaults_database_ec2.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        instance = merge(local.defaults_database_ec2.instance, {
          instance_type                = "r6i.xlarge"
          disable_api_stop             = true
          metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
        })

        ebs_volumes = merge(local.defaults_database_ec2.ebs_volumes, {
          "/dev/sda1" = { label = "root", size = 30 }
          "/dev/sdb"  = { label = "app", size = 100 } # /u01
          "/dev/sdc"  = { label = "app", size = 500 } # /u02
        })

        ebs_volume_config = merge(local.defaults_database_ec2.ebs_volume_config, {
          data = {
            total_size = 1500
          }
          flash = {
            total_size = 100
          }
        })

        secretsmanager_secrets = module.baseline_presets.ec2_instance.secretsmanager_secrets.oracle_19c

        tags = {
          pre-migration = "PDCDL00014"
          description   = "PD CSR Oracle secondary DB server"
          ami           = "base_ol_8_5"
          os-type       = "Linux"
          component     = "data"
          server-type   = "csr-db"
          backup        = "false" # opt out of mod platform default backup plan
        }
      })

      pd-csr-a-7-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-csr-a-7-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        tags = {
          pre-migration = "PDCAW00007"
          description   = "Application Server Region 1"
          os-type       = "Windows"
          ami           = "pd-csr-a-7-a"
          component     = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pd-csr-a-8-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-csr-a-8-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        tags = {
          pre-migration = "PDCAW00008"
          description   = "Application Server Region 2"
          os-type       = "Windows"
          ami           = "pd-csr-a-8-b"
          component     = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pd-csr-a-9-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-csr-a-9-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        tags = {
          pre-migration = "PDCAW00009"
          description   = "Application Server Region 3"
          os-type       = "Windows"
          ami           = "pd-csr-a-9-a"
          component     = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pd-csr-a-10-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-csr-a-10-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        tags = {
          pre-migration = "PDCAW00010"
          description   = "Application Server Region 4"
          os-type       = "Windows"
          ami           = "pd-csr-a-10-b"
          component     = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pd-csr-a-11-a = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-csr-a-11-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 112 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        tags = {
          pre-migration = "PDCAW00011"
          description   = "Application Server Region 5"
          os-type       = "Windows"
          ami           = "pd-csr-a-11-a"
          component     = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pd-csr-a-12-b = merge(local.defaults_app_ec2, {
        config = merge(local.defaults_app_ec2.config, {
          ami_name          = "pd-csr-a-12-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_app_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 } # root volume
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
        }
        tags = {
          pre-migration = "PDCAW00012"
          description   = "Application Server Region 6"
          os-type       = "Windows"
          ami           = "pd-csr-a-12-b"
          component     = "app"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pd-csr-w-1-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-csr-w-1-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        tags = {
          pre-migration = "PDCWW00001"
          description   = "Web Server Region 1 and 2"
          os-type       = "Windows"
          ami           = "pd-csr-w-1-a"
          component     = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pd-csr-w-2-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-csr-w-2-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        tags = {
          pre-migration = "PDCWW00002"
          description   = "Web Server Region 1 and 2"
          os-type       = "Windows"
          ami           = "pd-csr-w-2-b"
          component     = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pd-csr-w-3-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-csr-w-3-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        tags = {
          pre-migration = "PDCWW00003"
          description   = "Web Server Region 3 and 4"
          os-type       = "Windows"
          ami           = "pd-csr-w-3-a"
          component     = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pd-csr-w-4-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-csr-w-4-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 112 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        tags = {
          pre-migration = "PDCWW00004"
          description   = "Web Server Region 3 and 4"
          os-type       = "Windows"
          ami           = "pd-csr-w-4-b"
          component     = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pd-csr-w-5-a = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-csr-w-5-a"
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 112 }
          "/dev/sdd"  = { type = "gp3", size = 128 }
        }
        tags = {
          pre-migration = "PDCWW00005"
          description   = "Web Server Region 5 and 6"
          os-type       = "Windows"
          ami           = "pd-csr-w-5-a"
          component     = "web"
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
      })

      pd-csr-w-6-b = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          ami_name          = "pd-csr-w-6-b"
          availability_zone = "${local.region}b"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m5.4xlarge"
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 128 }
          "/dev/sdb"  = { type = "gp3", size = 128 }
          "/dev/sdc"  = { type = "gp3", size = 128 }
          "/dev/sdd"  = { type = "gp3", size = 112 }
        }
        tags = {
          pre-migration = "PDCWW00006"
          description   = "Web Server Region 5 and 6"
          os-type       = "Windows"
          ami           = "pd-csr-w-6-b"
          component     = "web"
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

    baseline_route53_zones = {
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
  }
}
