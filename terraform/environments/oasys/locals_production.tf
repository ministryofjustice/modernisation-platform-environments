# environment specific settings
locals {

  # cloudwatch monitoring config
  production_cloudwatch_monitoring_options = {}

  production_baseline_presets_options = {
    sns_topics = {
      pagerduty_integrations = {
        dso_pagerduty               = "oasys_alarms"
        dba_pagerduty               = "hmpps_shef_dba_low_priority"
        dba_high_priority_pagerduty = "hmpps_shef_dba_high_priority"
      }
    }
  }

  production_config = {

    ec2_common = {
      patch_approval_delay_days = 7
      patch_day                 = "THU"
    }

    baseline_s3_buckets     = {}
    baseline_ssm_parameters = {}

    baseline_secretsmanager_secrets = {
      "/oracle/database/PDOASYS" = local.secretsmanager_secrets_oasys_db
      "/oracle/database/PROASYS" = local.secretsmanager_secrets_oasys_db
      "/oracle/database/TROASYS" = local.secretsmanager_secrets_oasys_db
      "/oracle/database/DROASYS" = local.secretsmanager_secrets_oasys_db

      "/oracle/database/PDOASREP" = local.secretsmanager_secrets_db
      "/oracle/database/PDBIPINF" = local.secretsmanager_secrets_bip_db
      "/oracle/database/PDMISTRN" = local.secretsmanager_secrets_db
      "/oracle/database/PDONRSYS" = local.secretsmanager_secrets_db
      "/oracle/database/PDONRAUD" = local.secretsmanager_secrets_db
      "/oracle/database/PDONRBDS" = local.secretsmanager_secrets_db

      "/oracle/database/TRBIPINF" = local.secretsmanager_secrets_bip_db

      # for azure, remove when migrated to aws db
      "/oracle/database/OASPROD" = local.secretsmanager_secrets_oasys_db

      "/oracle/bip/production" = local.secretsmanager_secrets_bip
      "/oracle/bip/trn"        = local.secretsmanager_secrets_bip
    }

    baseline_iam_policies = {
      Ec2ProdWebPolicy = {
        description = "Permissions required for Prod Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PDOASYS/apex-passwords*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/OASPROD/apex-passwords*",
            ]
          }
        ]
      }
      Ec2PtcWebPolicy = {
        description = "Permissions required for practice Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PROASYS/apex-passwords*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/OASYSPTC/apex-passwords*",
            ]
          }
        ]
      }
      Ec2TrnWebPolicy = {
        description = "Permissions required for training Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/TROASYS/apex-passwords*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/OASYSTRN/apex-passwords*",
            ]
          }
        ]
      }
      Ec2ProdDatabasePolicy = {
        description = "Permissions required for Prod Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "s3:GetBucketLocation",
              "s3:GetObject",
              "s3:GetObjectTagging",
              "s3:ListBucket",
              "s3:PutObject",
              "s3:PutObjectAcl",
              "s3:PutObjectTagging",
              "s3:DeleteObject",
              "s3:RestoreObject",
            ]
            resources = [
              "arn:aws:s3:::prod-oasys-db-backup-bucket*",
              "arn:aws:s3:::prod-oasys-db-backup-bucket*/*",
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PD/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PD*/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/DR*/*",
            ]
          },
        ]
      }
      Ec2PtcTrnDatabasePolicy = {
        description = "Permissions required for practice and training Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "s3:GetBucketLocation",
              "s3:GetObject",
              "s3:GetObjectTagging",
              "s3:ListBucket",
              "s3:PutObject",
              "s3:PutObjectAcl",
              "s3:PutObjectTagging",
              "s3:DeleteObject",
              "s3:RestoreObject",
            ]
            resources = [
              "arn:aws:s3:::prod-oasys-db-backup-bucket*",
              "arn:aws:s3:::prod-oasys-db-backup-bucket*/*",
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
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PR/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PR*/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*TR/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/TR*/*",
            ]
          },
        ]
      }
      Ec2TrnBipPolicy = {
        description = "Permissions required for training Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*TR/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/TR*/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/trn/*",
            ]
          }
        ]
      }
      Ec2ProdBipPolicy = {
        description = "Permissions required for prod Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PD/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PD*/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/production/*",
            ]
          }
        ]
      }
    }

    baseline_ec2_instances = {
      "pd-oasys-db-a" = merge(local.database_a, {
        config = merge(local.database_a.config, {
          instance_profile_policies = concat(local.database_a.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        tags = merge(local.database_a.tags, {
          bip-db-name = "PDBIPINF"
          oracle-sids = "PDBIPINF PDOASYS"
        })
      })

      "pd-oasys-db-b" = merge(local.database_b, {
        config = merge(local.database_b.config, {
          instance_profile_policies = concat(local.database_b.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        tags = merge(local.database_b.tags, {
          bip-db-name = "PDBIPINF"
          oracle-sids = "PDBIPINF PDOASYS"
        })
      })

      "pd-onr-db-a" = merge(local.database_onr_a, {
        config = merge(local.database_onr_a.config, {
          instance_profile_policies = concat(local.database_onr_a.config.instance_profile_policies, [
            "Ec2ProdDatabasePolicy",
          ])
        })
        tags = merge(local.database_onr_a.tags, {
          instance-scheduling = "skip-scheduling"
          oracle-sids         = "PDMISTRN PDONRBDS PDONRSYS PDONRAUD PDOASREP"
        })
      })


      "ptctrn-oasys-db-a" = merge(local.database_a, {
        config = merge(local.database_a.config, {
          instance_profile_policies = concat(local.database_a.config.instance_profile_policies, [
            "Ec2PtcTrnDatabasePolicy",
          ])
        })
        instance = merge(local.database_a.instance, {
          instance_type = "r6i.xlarge"
        })
        ebs_volumes = {
          "/dev/sdb" = { # /u01
            size  = 100
            label = "app"
            type  = "gp3"
          }
          "/dev/sdc" = { # /u02
            size  = 500
            label = "app"
            type  = "gp3"
          }
          "/dev/sde" = { # DATA01
            label = "data"
            size  = 300
            type  = "gp3"
          }
          "/dev/sdj" = { # FLASH01
            label = "flash"
            type  = "gp3"
            size  = 200
          }
          "/dev/sds" = {
            label = "swap"
            type  = "gp3"
            size  = 2
          }
        }
        ebs_volume_config = {
          data = {
            iops       = 3000 # min 3000
            type       = "gp3"
            throughput = 125
            total_size = 200
          }
          flash = {
            iops       = 3000 # min 3000
            type       = "gp3"
            throughput = 125
            total_size = 50
          }
        }
        tags = merge(local.database_a.tags, {
          description       = "practice and training oasys database"
          oasys-environment = "ptctrn"
          bip-db-name       = "TRBIPINF"
          oracle-sids       = "PROASYS TROASYS TRBIPINF"
        })
      })

      "pd-oasys-bip-a" = merge(local.bip_a, {
        config = merge(local.bip_a.config, {
          instance_profile_policies = concat(local.bip_a.config.instance_profile_policies, [
            "Ec2ProdBipPolicy",
          ])
        })
        tags = merge(local.bip_a.tags, {
          bip-db-name       = "PDBIPINF"
          bip-db-hostname   = "pd-oasys-db-a"
          oasys-db-name     = "PDOASYS"
          oasys-db-hostname = "pd-oasys-db-a"
        })
      })

      "trn-oasys-bip-a" = merge(local.bip_a, {
        config = merge(local.bip_a.config, {
          instance_profile_policies = concat(local.bip_a.config.instance_profile_policies, [
            "Ec2TrnBipPolicy",
          ])
        })
        tags = merge(local.bip_a.tags, {
          bip-db-name       = "TRBIPINF"
          bip-db-hostname   = "ptctrn-oasys-db-a"
          oasys-db-name     = "TROASYS"
          oasys-db-hostname = "ptctrn-oasys-db-a"
          oasys-environment = "trn"
        })
      })
    }


    baseline_ec2_autoscaling_groups = {
      "pd-oasys-web-a" = merge(local.webserver, {
        config = merge(local.webserver.config, {
          instance_profile_policies = concat(local.webserver.config.instance_profile_policies, [
            "Ec2ProdWebPolicy",
          ])
        })
        autoscaling_group = merge(local.webserver.autoscaling_group, {
          desired_capacity = 4
          max_size         = 4
        })
        tags = merge(local.webserver.tags, {
          oracle-db-sid      = "PDOASYS"
          oracle-db-hostname = "db.oasys.hmpps-production.modernisation-platform.internal"
        })
      })

      "ptc-oasys-web-a" = merge(local.webserver, {
        config = merge(local.webserver.config, {
          ssm_parameters_prefix     = "ec2-web-ptc/"
          iam_resource_names_prefix = "ec2-web-ptc"
          instance_profile_policies = concat(local.webserver.config.instance_profile_policies, [
            "Ec2PtcWebPolicy",
          ])
        })
        tags = merge(local.webserver.tags, {
          description        = "${local.environment} practice oasys web"
          oasys-environment  = "ptc"
          oracle-db-sid      = "PROASYS"
          oracle-db-hostname = "db.ptc.oasys.hmpps-production.modernisation-platform.internal"
        })
      })

      "trn-oasys-web-a" = merge(local.webserver, {
        config = merge(local.webserver.config, {
          ssm_parameters_prefix     = "ec2-web-trn/"
          iam_resource_names_prefix = "ec2-web-trn"
          instance_profile_policies = concat(local.webserver.config.instance_profile_policies, [
            "Ec2TrnWebPolicy",
          ])
        })
        tags = merge(local.webserver.tags, {
          description        = "${local.environment} training oasys web"
          oasys-environment  = "trn"
          oracle-db-sid      = "TROASYS"
          oracle-db-hostname = "db.trn.oasys.hmpps-production.modernisation-platform.internal"
        })
      })
    }

    # If your DNS records are in Fix 'n' Go, setup will be a 2 step process, see the acm_certificate module readme
    # if making changes, comment out the listeners that use the cert, edit the cert, recreate the listeners
    baseline_acm_certificates = {
      "pd_oasys_cert" = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = "oasys.service.justice.gov.uk"
        subject_alternate_names = [
          "*.oasys.service.justice.gov.uk",
          "*.int.oasys.service.justice.gov.uk",
          "bridge-oasys.az.justice.gov.uk",
          "oasys.az.justice.gov.uk",
          "p-oasys.az.justice.gov.uk",
          "*.oasys.az.justice.gov.uk",
          "*.bridge-oasys.az.justice.gov.uk",
          "*.p-oasys.az.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "cert for oasys ${local.environment} domains"
        }
      }
    }

    baseline_lbs = {
      public = {
        internal_lb              = false
        access_logs              = true
        s3_versioning            = false
        force_destroy_bucket     = true
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 3600 # 60 is default
        security_groups          = ["public_lb"]
        subnets                  = module.environment.subnets["public"].ids
        tags                     = local.tags

        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-TLS13-1-2-2021-06"
            certificate_names_or_arns = ["pd_oasys_cert"]
            default_action = {
              type = "fixed-response"
              fixed_response = {
                content_type = "text/plain"
                message_body = "Use www.oasys.service.justice.gov.uk, or for practice ptc.oasys.service.justice.gov.uk, or for training trn.oasys.service.justice.gov.uk"
                status_code  = "200"
              }
            }
            # default_action = {
            #   type              = "forward"
            #   target_group_name = "pd-oasys-web-a-pb-http-8080"
            # }
            rules = {
              pd-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-oasys-web-a-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "oasys.service.justice.gov.uk",
                        "bridge-oasys.az.justice.gov.uk",
                        "www.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              ptc-web-http-8080 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "ptc-oasys-web-a-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "ptc.oasys.service.justice.gov.uk",
                        "practice.bridge-oasys.az.justice.gov.uk",
                        "practice.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              trn-web-http-8080 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "trn-oasys-web-a-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "trn.oasys.service.justice.gov.uk",
                        "training.bridge-oasys.az.justice.gov.uk",
                        "training.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              # pd-web-b-http-8080 = {
              #   priority = 200
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "pd-oasys-web-b-pb-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = [
              #           "b.oasys.service.justice.gov.uk",
              #         ]
              #       }
              #     }
              #   ]
              # }
            }
          }
        }
      }
      private = {
        internal_lb              = true
        access_logs              = true
        s3_versioning            = false
        force_destroy_bucket     = false
        enable_delete_protection = false
        existing_target_groups   = {}
        idle_timeout             = 3600 # 60 is default
        security_groups          = ["private_lb"]
        subnets                  = module.environment.subnets["private"].ids
        tags                     = local.tags
        listeners = {
          https = {
            port                      = 443
            protocol                  = "HTTPS"
            ssl_policy                = "ELBSecurityPolicy-2016-08"
            certificate_names_or_arns = ["pd_oasys_cert"]
            # default_action = {
            #   type = "fixed-response"
            #   fixed_response = {
            #     content_type = "text/plain"
            #     message_body = "use int.oasys.service.justice.gov.uk, or for practice ptc-int.oasys.service.justice.gov.uk, or for training trn-int.oasys.service.justice.gov.uk"
            #     status_code  = "200"
            #   }
            # }
            default_action = {
              type = "redirect"
              redirect = {
                host        = "int.oasys.service.justice.gov.uk"
                port        = "443"
                protocol    = "HTTPS"
                status_code = "HTTP_302"
              }
            }
            # default_action = {
            #   type              = "forward"
            #   target_group_name = "pd-oasys-web-a-pv-http-8080"
            # }
            rules = {
              pd-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pd-oasys-web-a-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "int.oasys.service.justice.gov.uk",
                        "oasys-ukwest.oasys.az.justice.gov.uk",
                        # "oasys.az.justice.gov.uk",
                        "p-oasys.az.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              ptc-web-http-8080 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "ptc-oasys-web-a-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "ptc-int.oasys.service.justice.gov.uk",
                        "practice.int.oasys.service.justice.gov.uk",
                        "practice.oasys.az.justice.gov.uk",
                        "practice.p-oasys.az.justice.gov.uk",
                        "practice-ukwest.oasys.az.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              trn-web-http-8080 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "trn-oasys-web-a-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "trn-int.oasys.service.justice.gov.uk",
                        "training.int.oasys.service.justice.gov.uk",
                        "training.oasys.az.justice.gov.uk",
                        "training.p-oasys.az.justice.gov.uk",
                        "training-ukwest.oasys.az.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              # pd-web-b-http-8080 = {
              #   priority = 200
              #   actions = [{
              #     type              = "forward"
              #     target_group_name = "pd-oasys-web-b-pv-http-8080"
              #   }]
              #   conditions = [
              #     {
              #       host_header = {
              #         values = [
              #           "b-int.oasys.service.justice.gov.uk",
              #         ]
              #       }
              #     }
              #   ]
              # }
            }
          }
        }
      }
    }

    baseline_route53_zones = {
      #
      # public
      #
      "hmpps-production.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "db.oasys", type = "CNAME", ttl = "3600", records = ["pd-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.trn.oasys", type = "CNAME", ttl = "3600", records = ["ptctrn-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.ptc.oasys", type = "CNAME", ttl = "3600", records = ["ptctrn-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.onr", type = "CNAME", ttl = "3600", records = ["pd-onr-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
      "oasys.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "", type = "A", lbs_map_key = "public" },    # oasys.service.justice.gov.uk
          { name = "www", type = "A", lbs_map_key = "public" }, # www.oasys.service.justice.gov.uk
          { name = "a", type = "A", lbs_map_key = "public" },   # a.oasys.service.justice.gov.uk
          { name = "b", type = "A", lbs_map_key = "public" },   # b.oasys.service.justice.gov.uk
          { name = "practice", type = "A", lbs_map_key = "public" },
          { name = "ptc", type = "A", lbs_map_key = "public" },
          { name = "training", type = "A", lbs_map_key = "public" },
          { name = "trn", type = "A", lbs_map_key = "public" },
          { name = "int", type = "A", lbs_map_key = "private" },   # int.oasys.service.justice.gov.uk
          { name = "a-int", type = "A", lbs_map_key = "private" }, # a-int.oasys.service.justice.gov.uk
          { name = "b-int", type = "A", lbs_map_key = "private" }, # b-int.oasys.service.justice.gov.uk
          { name = "practice.int", type = "A", lbs_map_key = "private" },
          { name = "ptc-int", type = "A", lbs_map_key = "private" },
          { name = "training.int", type = "A", lbs_map_key = "private" },
          { name = "trn-int", type = "A", lbs_map_key = "private" },
        ]
        records = [
          { name = "db.onr", type = "CNAME", ttl = "3600", records = ["pd-onr-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db", type = "CNAME", ttl = "3600", records = ["pd-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db-b", type = "CNAME", ttl = "3600", records = ["pd-oasys-db-b.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },

          { name = "db.pp.onr", type = "CNAME", ttl = "3600", records = ["pp-onr-db-a.oasys.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "pp", type = "CNAME", ttl = "3600", records = ["public-lb-2107358561.eu-west-2.elb.amazonaws.com"] },
          { name = "db.pp", type = "CNAME", ttl = "3600", records = ["pp-oasys-db-a.oasys.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "pp-a", type = "CNAME", ttl = "3600", records = ["public-lb-2107358561.eu-west-2.elb.amazonaws.com"] },
          { name = "pp-a-int", type = "CNAME", ttl = "3600", records = ["internal-private-lb-212442533.eu-west-2.elb.amazonaws.com"] },
          { name = "pp-int", type = "CNAME", ttl = "3600", records = ["internal-private-lb-212442533.eu-west-2.elb.amazonaws.com"] },

          { name = "t1", type = "CNAME", ttl = "3600", records = ["public-lb-1856376477.eu-west-2.elb.amazonaws.com"] },
          { name = "ords.t1", type = "CNAME", ttl = "3600", records = ["public-lb-1856376477.eu-west-2.elb.amazonaws.com"] },
          { name = "t1-int", type = "CNAME", ttl = "3600", records = ["internal-private-lb-1575012313.eu-west-2.elb.amazonaws.com"] },

          { name = "t2", type = "CNAME", ttl = "3600", records = ["public-lb-1856376477.eu-west-2.elb.amazonaws.com"] },
          { name = "ords.t2", type = "CNAME", ttl = "3600", records = ["public-lb-1856376477.eu-west-2.elb.amazonaws.com"] },
          { name = "t2-b", type = "CNAME", ttl = "3600", records = ["public-lb-1856376477.eu-west-2.elb.amazonaws.com"] },
          { name = "t2-b-int", type = "CNAME", ttl = "3600", records = ["internal-private-lb-1575012313.eu-west-2.elb.amazonaws.com"] },
          { name = "t2-int", type = "CNAME", ttl = "3600", records = ["internal-private-lb-1575012313.eu-west-2.elb.amazonaws.com"] },

          { name = "_4f7f9316bc4eaa8e9637c17aa36966b1", type = "CNAME", ttl = "86400", records = ["_83c5b5d8980ae954f876dd1b51417d43.qxcwttcyyb.acm-validations.aws."] },
          { name = "_9f1b86e95d13d2cc7b9629f67d672c40", type = "CNAME", ttl = "86400", records = ["_7ea92a123c65795698dd19834dd71f61.fdbjvjdfdx.acm-validations.aws."] },
          { name = "_26aaae7b839510727c2dd323b483ea5d.pp", type = "CNAME", ttl = "86400", records = ["_72222d02a82256bb6d75c872bc7bc1aa.qxcwttcyyb.acm-validations.aws."] },
          { name = "_c3a661930d89914b2b25aac7d9947b3d.pp-a", type = "CNAME", ttl = "86400", records = ["_d57e6b487b03e7a7fd25e934671601cc.plkdfvcnsy.acm-validations.aws."] },
          { name = "_315500c40ef2d43ce87898e24be41f4e.pp-a-int", type = "CNAME", ttl = "86400", records = ["_be7c7a6b253419ba86f08cacabb28678.plkdfvcnsy.acm-validations.aws."] },
          { name = "_50d671c38e9c0d7692603c84d7ed066f.pp-b", type = "CNAME", ttl = "86400", records = ["_3aa768d4e3d8825ba1c8f2c2a154e7f4.plkdfvcnsy.acm-validations.aws."] },
          { name = "_a1ba1dd6ae3372f75a678b39e62364e0.pp-b-int", type = "CNAME", ttl = "86400", records = ["_eba205f55455280dbf39807cc4cd4a4f.plkdfvcnsy.acm-validations.aws."] },
          { name = "_b895eab0227a1d047f714060e0cd970f.pp-int", type = "CNAME", ttl = "86400", records = ["_9beca5f6af7ab9851e446fb506c15558.plkdfvcnsy.acm-validations.aws."] },
          { name = "_16d62060ae34f0c7e45cd3303d1369de.ords.t1", type = "CNAME", ttl = "86400", records = ["_3ace3d679497ac88b6b29516dc3e92ff.jsxlrrpjwm.acm-validations.aws."] },
          { name = "_93b16605cbf55e463d0ee7954b20c94d.t2", type = "CNAME", ttl = "86400", records = ["_51d8f8d87c9b9c07a1b1602bb68a1634.fcgjwsnkyp.acm-validations.aws."] },
          { name = "_594f919f3d6c4e462084ee328bdb3236.ords.t2", type = "CNAME", ttl = "86400", records = ["_734a121cabbafd1e18bb96a0f2de6ac6.jsxlrrpjwm.acm-validations.aws."] },
        ]
      }

      #
      # internal/private
      #
      "hmpps-production.modernisation-platform.internal" = {
        vpc = {    # this makes it a private hosted zone
          id = module.environment.vpc.id
        }
        records = [
          { name = "db.trn.oasys", type = "CNAME", ttl = "3600", records = ["ptctrn-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.ptc.oasys", type = "CNAME", ttl = "3600", records = ["ptctrn-oasys-db-a.oasys.hmpps-production.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.oasys", type = "CNAME", ttl = "3600", records = ["pd-oasys-db-a.oasys.hmpps-production.modernisation-platform.internal"] }, # db.oasys.hmpps-production.modernisation-platform.internal
          { name = "db.onr", type = "CNAME", ttl = "3600", records = ["pd-onr-db-a.oasys.hmpps-production.modernisation-platform.internal"] },                         # db.onr.hmpps-production.modernisation-platform.internal
        ]
      }
    }

    baseline_cloudwatch_log_groups = {
      session-manager-logs = {
        retention_in_days = 400
      }
      cwagent-var-log-messages = {
        retention_in_days = 90
      }
      cwagent-var-log-secure = {
        retention_in_days = 400
      }
      cwagent-windows-system = {
        retention_in_days = 90
      }
      cwagent-oasys-autologoff = {
        retention_in_days = 400
      }
      cwagent-web-logs = {
        retention_in_days = 90
      }
    }
  }
}
