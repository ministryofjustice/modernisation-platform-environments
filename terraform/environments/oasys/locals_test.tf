locals {

  baseline_presets_test = {
    options = {

      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "oasys-test"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    acm_certificates = {
      t2_oasys_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "t2.oasys.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "*.oasys.service.justice.gov.uk",
          "*.hmpp-azdt.justice.gov.uk",
          "ords.t2.oasys.service.justice.gov.uk",
          "ords.t1.oasys.service.justice.gov.uk",
        ]
        tags = {
          description = "cert for t2 oasys test domains"
        }
      }
    }

    cloudwatch_dashboards = {
      "CloudWatch-Default" = {
        periodOverride = "auto"
        start          = "-PT6H"
        widget_groups = [
          module.baseline_presets.cloudwatch_dashboard_widget_groups.lb,
          local.cloudwatch_dashboard_widget_groups.db,
          local.cloudwatch_dashboard_widget_groups.onr,
          local.cloudwatch_dashboard_widget_groups.ec2,
          module.baseline_presets.cloudwatch_dashboard_widget_groups.ssm_command,
        ]
      }
    }

    ec2_autoscaling_groups = {
      t1-oasys-web-a = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_schedules = {
          scale_up   = { recurrence = "0 5 * * Mon-Fri", desired_capacity = 0 } ####
          scale_down = { recurrence = "0 19 * * Mon-Fri", desired_capacity = 0 }
        }
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name                  = "oasys_webserver_release_*"
          availability_zone         = "eu-west-2a"
          iam_resource_names_prefix = "ec2-web-t1"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2T1WebPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
          instance_type = "t3.small"
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          description        = "t1 oasys web"
          oasys-environment  = "t1"
          oracle-db-hostname = "db.t1.oasys.hmpps-test.modernisation-platform.internal"
          oracle-db-sid      = "T1OASYS" # for each env using azure DB will need to be OASPROD
        })
      })

      t2-oasys-web-a = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_schedules = {
          scale_up   = { recurrence = "0 5 * * Mon-Fri", desired_capacity = 0 } ###ß
          scale_down = { recurrence = "0 19 * * Mon-Fri", desired_capacity = 0 }
        }
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name                  = "oasys_webserver_release_*"
          availability_zone         = "eu-west-2a"
          iam_resource_names_prefix = "ec2-web-t2"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2T2WebPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
          instance_type = "t3.small"
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          description        = "t2 oasys web"
          oasys-environment  = "t2"
          oracle-db-hostname = "db.t2.oasys.hmpps-test.modernisation-platform.internal"
          oracle-db-sid      = "T2OASYS" # for each env using azure DB will need to be OASPROD
        })
      })

      t2-oasys-web-b = merge(local.ec2_autoscaling_groups.web, {
        # For SAN project (OASYS replacement) requested by Howard Smith
        # Autoscaling disabled as initially server will be configured manually
        autoscaling_group = merge(local.ec2_autoscaling_groups.web.autoscaling_group, {
          desired_capacity = 1 # setting to 0 leaves in a stopped state because of the warm_pool config below ####
          warm_pool = {
            min_size          = 0
            reuse_on_scale_in = true
          }
        })
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name                  = "oasys_webserver_release_*"
          availability_zone         = "eu-west-2b"
          iam_resource_names_prefix = "ec2-web-t2"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2T2WebPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
          instance_type = "t3.small"
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          description        = "t2 oasys web"
          oasys-environment  = "t2"
          oracle-db-hostname = "db.t2.oasys.hmpps-test.modernisation-platform.internal"
          oracle-db-sid      = "T2OASYS2"
        })
      })
    }

    ec2_instances = {
      t1-oasys-bip-a = merge(local.ec2_instances.bip, {
        config = merge(local.ec2_instances.bip.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip.config.instance_profile_policies, [
            "Ec2T1BipPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip.instance, {
          ami = "ami-0d206b8546ea2b68a" # to prevent instances being re-created due to recreated AMI
          instance_type = "t3.medium"
        })
        user_data_cloud_init = merge(local.ec2_instances.bip.user_data_cloud_init, {
          args = merge(local.ec2_instances.bip.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.bip.tags, {
          bip-db-hostname     = "t1-oasys-db-a"
          bip-db-name         = "T1BIPINF"
          instance-scheduling = "skip-scheduling"
          oasys-db-hostname   = "t1-oasys-db-a"
          oasys-db-name       = "T1OASYS"
          oasys-environment   = "t1"
        })
      })

      t1-oasys-db-a = merge(local.ec2_instances.db19c, {
        config = merge(local.ec2_instances.db19c.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db19c.config.instance_profile_policies, [
            "Ec2T1DatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 200 } # /u01
          "/dev/sdc" = { label = "app", size = 500 } # /u02
          "/dev/sde" = { label = "data", size = 500 }
          "/dev/sdf" = { label = "data", size = 50 }
          "/dev/sdj" = { label = "flash", size = 50 }
          "/dev/sds" = { label = "swap", size = 2 }
        }
        instance = merge(local.ec2_instances.db19c.instance, {
          disable_api_termination = true
          instance_type           = "r6i.large"
        })
        tags = merge(local.ec2_instances.db19c.tags, {
          bip-db-name         = "T1BIPINF"
          description         = "t1 oasys database"
          instance-scheduling = "skip-scheduling"
          oasys-environment   = "t1"
          oracle-sids         = "T1BIPINF T1MISTRN T1OASREP T1OASYS T1ONRAUD T1ONRBDS T1ONRSYS"
        })
      })

      t2-oasys-bip-a = merge(local.ec2_instances.bip, {
        config = merge(local.ec2_instances.bip.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip.config.instance_profile_policies, [
            "Ec2T2BipPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip.instance, {
          ami = "ami-0d206b8546ea2b68a" # to prevent instances being re-created due to recreated AMI
          instance_type           = "t3.medium"
        })
        user_data_cloud_init = merge(local.ec2_instances.bip.user_data_cloud_init, {
          args = merge(local.ec2_instances.bip.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.bip.tags, {
          bip-db-hostname     = "t2-oasys-db-a"
          bip-db-name         = "T2BIPINF"
          instance-scheduling = "skip-scheduling"
          oasys-db-hostname   = "t2-oasys-db-a"
          oasys-db-name       = "T2OASYS"
          oasys-environment   = "t2"
        })
      })

      t2-oasys-db-a = merge(local.ec2_instances.db19c, {
        config = merge(local.ec2_instances.db19c.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db19c.config.instance_profile_policies, [
            "Ec2T2DatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 200 } # /u01
          "/dev/sdc" = { label = "app", size = 500 } # /u02
          "/dev/sde" = { label = "data", size = 500 }
          "/dev/sdf" = { label = "data", size = 500 }
          "/dev/sdj" = { label = "flash", size = 200 }
          "/dev/sds" = { label = "swap", size = 4 }
        }
        instance = merge(local.ec2_instances.db19c.instance, {
          disable_api_termination = true
          instance_type           = "r6i.large"
        })
        tags = merge(local.ec2_instances.db19c.tags, {
          bip-db-name         = "T2BIPINF"
          description         = "t2 oasys database"
          instance-scheduling = "skip-scheduling"
          oasys-environment   = "t2"
          oracle-sids         = "T2BIPINF T2MISTRN T2OASREP T2OASYS T2ONRAUD T2ONRBDS T2ONRSYS"
        })
      })

      t2-onr-db-a = merge(local.ec2_instances.db11g, { # needs the terraform aws provider/user-data fix + resize
        config = merge(local.ec2_instances.db11g.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db11g.config.instance_profile_policies, [
            "Ec2T2DatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 100 } # /u01
          "/dev/sdc" = { label = "app", size = 500 } # /u02
          "/dev/sde" = { label = "data", size = 2000 }
          "/dev/sdj" = { label = "flash", size = 600 }
          "/dev/sds" = { label = "swap", size = 2 }
        }
        instance = merge(local.ec2_instances.db11g.instance, {
          disable_api_termination = true
          instance_type           = "r6i.xlarge"
          #instance_type           = "r6i.large"
        })
        tags = merge(local.ec2_instances.db11g.tags, {
          instance-scheduling = "skip-scheduling"
          oasys-environment   = "t2"
          oracle-sids         = "T2BOSYS T2BOAUD"
        })
      })
    }

    iam_policies = {
      Ec2T1BipPolicy = {
        description = "Permissions required for T1 Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/t1/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T1/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T1*/bip-*",
            ]
          }
        ]
      }
      Ec2T1DatabasePolicy = {
        description = "Permissions required for T1 Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T1/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T1*/*",
            ]
          }
        ]
      }
      Ec2T1WebPolicy = {
        description = "Permissions required for T1 Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T1OASYS/apex-passwords*",
            ]
          }
        ]
      }

      Ec2T2BipPolicy = {
        description = "Permissions required for T2 Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T2/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T2*/bip-*",
            ]
          }
        ]
      }
      Ec2T2DatabasePolicy = {
        description = "Permissions required for T2 Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*T2/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T2*/*",
            ]
          }
        ]
      }
      Ec2T2WebPolicy = {
        description = "Permissions required for T2 Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T2OASYS/apex-passwords*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/T2OASYS2/apex-passwords*",
            ]
          }
        ]
      }
    }

    # options for LBs https://docs.google.com/presentation/d/1RpXpfNY_hw7FjoMw0sdMAdQOF7kZqLUY6qVVtLNavWI/edit?usp=sharing
    lbs = {
      public = merge(local.lbs.public, {
        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            certificate_names_or_arns = ["t2_oasys_cert"]

            rules = {
              t2-web-a-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-oasys-web-a-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t2.oasys.service.justice.gov.uk",
                        "t2-a.oasys.service.justice.gov.uk",
                        "ords.t2.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              t2-web-b-http-8080 = {
                priority = 150
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-oasys-web-b-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t2-b.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              t1-web-http-8080 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-oasys-web-a-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t1.oasys.service.justice.gov.uk",
                        "t1-a.oasys.service.justice.gov.uk",
                        "ords.t1.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
            }
          })
        })
      })

      private = merge(local.lbs.private, {
        listeners = merge(local.lbs.private.listeners, {
          https = merge(local.lbs.private.listeners.https, {
            certificate_names_or_arns = ["t2_oasys_cert"]

            rules = {
              t2-web-a-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-oasys-web-a-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t2-int.oasys.service.justice.gov.uk",
                        "t2-a-int.oasys.service.justice.gov.uk",
                        "t2-oasys.hmpp-azdt.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              t2-web-b-http-8080 = {
                priority = 150
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-oasys-web-b-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t2-b-int.oasys.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              t1-web-http-8080 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-oasys-web-a-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "t1-int.oasys.service.justice.gov.uk",
                        "t1-a-int.oasys.service.justice.gov.uk",
                        "t1-oasys.hmpp-azdt.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
            }
          })
        })
      })
    }

    route53_zones = {
      "hmpps-test.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "db.t2.oasys", type = "CNAME", ttl = "3600", records = ["t2-oasys-db-a.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.t1.oasys", type = "CNAME", ttl = "3600", records = ["t1-oasys-db-a.oasys.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
      "hmpps-test.modernisation-platform.internal" = {
        vpc = { # this makes it a private hosted zone
          id = module.environment.vpc.id
        }
        records = [
          { name = "db.t2.oasys", type = "CNAME", ttl = "3600", records = ["t2-oasys-db-a.oasys.hmpps-test.modernisation-platform.internal"] },
          { name = "db.t1.oasys", type = "CNAME", ttl = "3600", records = ["t1-oasys-db-a.oasys.hmpps-test.modernisation-platform.internal"] },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/bip/t1" = local.secretsmanager_secrets.bip
      "/oracle/bip/t2" = local.secretsmanager_secrets.bip

      "/oracle/database/T1OASYS"  = local.secretsmanager_secrets.db_oasys
      "/oracle/database/T1OASREP" = local.secretsmanager_secrets.db
      "/oracle/database/T1AZBIPI" = local.secretsmanager_secrets.db_bip
      "/oracle/database/T1BIPINF" = local.secretsmanager_secrets.db_bip
      "/oracle/database/T1MISTRN" = local.secretsmanager_secrets.db
      "/oracle/database/T1ONRSYS" = local.secretsmanager_secrets.db
      "/oracle/database/T1ONRAUD" = local.secretsmanager_secrets.db
      "/oracle/database/T1ONRBDS" = local.secretsmanager_secrets.db

      "/oracle/database/T2OASYS"  = local.secretsmanager_secrets.db_oasys
      "/oracle/database/T2OASYS2" = local.secretsmanager_secrets.db_oasys
      "/oracle/database/T2OASREP" = local.secretsmanager_secrets.db
      "/oracle/database/T2AZBIPI" = local.secretsmanager_secrets.db_bip
      "/oracle/database/T2BIPINF" = local.secretsmanager_secrets.db_bip
      "/oracle/database/T2MISTRN" = local.secretsmanager_secrets.db
      "/oracle/database/T2ONRSYS" = local.secretsmanager_secrets.db
      "/oracle/database/T2ONRAUD" = local.secretsmanager_secrets.db
      "/oracle/database/T2ONRBDS" = local.secretsmanager_secrets.db

      "/oracle/database/T2BOSYS" = local.secretsmanager_secrets.db_bip
      "/oracle/database/T2BOAUD" = local.secretsmanager_secrets.db_bip
    }
  }
}




