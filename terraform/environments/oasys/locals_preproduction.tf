locals {

  baseline_presets_preproduction = {
    options = {
      enable_xsiam_cloudwatch_integration = true
      enable_xsiam_s3_integration         = true
      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "oasys-preproduction"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    # If your DNS records are in Fix 'n' Go, setup will be a 2 step process, see the acm_certificate module readme
    # if making changes, comment out the listeners that use the cert, edit the cert, recreate the listeners
    acm_certificates = {
      pp_oasys_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "pp.oasys.service.justice.gov.uk"
        external_validation_records_created = true
        subject_alternate_names = [
          "pp-int.oasys.service.justice.gov.uk",
          "bridge-pp-oasys.az.justice.gov.uk",
          "pp-oasys.az.justice.gov.uk",
          "*.pp-oasys.az.justice.gov.uk",
        ]
        tags = {
          description = "cert for oasys preproduction domains"
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
      pp-oasys-web-a = merge(local.ec2_autoscaling_groups.web, {
        autoscaling_schedules = {
          scale_up   = { recurrence = "0 5 * * Mon-Fri" }
          scale_down = { recurrence = "0 19 * * Mon-Fri", desired_capacity = 0 }
        }
        config = merge(local.ec2_autoscaling_groups.web.config, {
          ami_name                  = "oasys_webserver_release_*"
          iam_resource_names_prefix = "ec2-web-pp"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2PreprodWebPolicy",
          ])
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          oracle-db-hostname = "db.pp.oasys.hmpps-preproduction.modernisation-platform.internal"
          oracle-db-sid      = "PPOASYS" # "OASPROD"
          oasys-environment  = "preproduction"
        })
      })
    }

    ec2_instances = {
      pp-oasys-bip-a = merge(local.ec2_instances.bip, {
        config = merge(local.ec2_instances.bip.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.bip.config.instance_profile_policies, [
            "Ec2PreprodBipPolicy",
          ])
        })
        instance = merge(local.ec2_instances.bip.instance, {
          ami = "ami-0d206b8546ea2b68a" # to prevent instances being re-created due to recreated AMI
        })
        tags = merge(local.ec2_instances.bip.tags, {
          bip-db-hostname     = "pp-oasys-db-a"
          bip-db-name         = "PPBIPINF"
          instance-scheduling = "skip-scheduling"
          oasys-db-hostname   = "pp-oasys-db-a"
          oasys-db-name       = "PPOASYS"
          oasys-environment   = "preproduction"
        })
      })

      pp-oasys-db-a = merge(local.ec2_instances.db19c, {
        config = merge(local.ec2_instances.db19c.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db19c.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 200 }  # /u01
          "/dev/sdc" = { label = "app", size = 1000 } # /u02
          "/dev/sde" = { label = "data", size = 2000 }
          "/dev/sdf" = { label = "data", size = 2000 }
          "/dev/sdj" = { label = "flash", size = 1000 }
          "/dev/sds" = { label = "swap", size = 2 }
        }
        instance = merge(local.ec2_instances.db19c.instance, {
          disable_api_termination = true
          instance_type           = "r6i.2xlarge"
        })
        tags = merge(local.ec2_instances.db19c.tags, {
          bip-db-name         = "PPBIPINF"
          instance-scheduling = "skip-scheduling"
          oasys-environment   = "preproduction"
          oracle-sids         = "PPBIPINF PPOASYS"
        })
      })

      pp-onr-db-a = merge(local.ec2_instances.db11g, {
        config = merge(local.ec2_instances.db11g.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db11g.config.instance_profile_policies, [
            "Ec2PreprodDatabasePolicy",
          ])
        })
        instance = merge(local.ec2_instances.db11g.instance, {
          disable_api_termination = true
          instance_type           = "r6i.2xlarge"
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 100 } # /u01
          "/dev/sdc" = { label = "app", size = 500 } # /u02
          "/dev/sde" = { label = "data", size = 2000 }
          "/dev/sdj" = { label = "flash", size = 600 }
          "/dev/sds" = { label = "swap", size = 2 }
        }
        user_data_cloud_init = merge(local.ec2_instances.db11g.user_data_cloud_init, {
          args = merge(local.ec2_instances.db11g.user_data_cloud_init.args, {
            branch = "oracle_11g_oasys_patchset_addition"
          })
        })
        tags = merge(local.ec2_instances.db11g.tags, {
          instance-scheduling = "skip-scheduling"
          oasys-environment   = "preproduction"
          oracle-sids         = "PPONRBDS PPOASREP PPONRSYS PPONRAUD"
        })
      })
    }

    iam_policies = {
      Ec2PreprodBipPolicy = {
        description = "Permissions required for preprod Bip EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PP/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PP*/bip-*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/bip/preproduction/*",
            ]
          }
        ]
      }
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
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*PP/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PP*/*",
            ]
          },
        ]
      }
      Ec2PreprodWebPolicy = {
        description = "Permissions required for Preprod Web EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/PPOASYS/apex-passwords*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/OASPROD/apex-passwords*",
            ]
          }
        ]
      }
    }

    # options for LBs https://docs.google.com/presentation/d/1RpXpfNY_hw7FjoMw0sdMAdQOF7kZqLUY6qVVtLNavWI/edit?usp=sharing
    lbs = {
      public = merge(local.lbs.public, {

        s3_notification_queues = {
          "cortex-xsiam-s3-public-alb-log-collection" = {
            events    = ["s3:ObjectCreated:*"]
            queue_arn = "cortex-xsiam-s3-alb-log-collection"
          }
        }

        listeners = merge(local.lbs.public.listeners, {
          https = merge(local.lbs.public.listeners.https, {
            certificate_names_or_arns = ["pp_oasys_cert"]

            rules = {
              pp-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-oasys-web-a-pb-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "pp.oasys.service.justice.gov.uk",
                        "pp-a.oasys.service.justice.gov.uk",
                        "bridge-pp-oasys.az.justice.gov.uk"
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

        s3_notification_queues = {
          "cortex-xsiam-s3-private-alb-log-collection" = {
            events    = ["s3:ObjectCreated:*"]
            queue_arn = "cortex-xsiam-s3-alb-log-collection"
          }
        }

        listeners = merge(local.lbs.private.listeners, {
          https = merge(local.lbs.private.listeners.https, {
            certificate_names_or_arns = ["pp_oasys_cert"]

            default_action = {
              type = "redirect"
              redirect = {
                host        = "pp-int.oasys.service.justice.gov.uk"
                port        = "443"
                protocol    = "HTTPS"
                status_code = "HTTP_302"
              }
            }

            rules = {
              pp-web-http-8080 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "pp-oasys-web-a-pv-http-8080"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [
                        "pp-int.oasys.service.justice.gov.uk",
                        "pp-a-int.oasys.service.justice.gov.uk",
                        "pp-oasys.az.justice.gov.uk",
                        "oasys-ukwest.pp-oasys.az.justice.gov.uk",
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
      "hmpps-preproduction.modernisation-platform.service.justice.gov.uk" = {
        records = [
          { name = "db.pp.oasys", type = "CNAME", ttl = "3600", records = ["pp-oasys-db-a.oasys.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
          { name = "db.pp.onr", type = "CNAME", ttl = "3600", records = ["pp-onr-db-a.oasys.hmpps-preproduction.modernisation-platform.service.justice.gov.uk"] },
        ]
      }
      "hmpps-preproduction.modernisation-platform.internal" = {
        vpc = { # this makes it a private hosted zone
          id = module.environment.vpc.id
        }
        records = [
          { name = "db.pp.oasys", type = "CNAME", ttl = "3600", records = ["pp-oasys-db-a.oasys.hmpps-preproduction.modernisation-platform.internal"] },
          { name = "db.pp.onr", type = "CNAME", ttl = "3600", records = ["pp-onr-db-a.oasys.hmpps-preproduction.modernisation-platform.internal"] },
        ]
      }
    }

    secretsmanager_secrets = {
      "/oracle/bip/preproduction" = local.secretsmanager_secrets.bip
      "/oracle/database/PPOASYS"  = local.secretsmanager_secrets.db_oasys
      "/oracle/database/PPOASREP" = local.secretsmanager_secrets.db
      "/oracle/database/PPBIPINF" = local.secretsmanager_secrets.db_bip
      "/oracle/database/PPMISTRN" = local.secretsmanager_secrets.db
      "/oracle/database/PPONRSYS" = local.secretsmanager_secrets.db
      "/oracle/database/PPONRAUD" = local.secretsmanager_secrets.db
      "/oracle/database/PPONRBDS" = local.secretsmanager_secrets.db
      "/oracle/database/PPMISTN2" = local.secretsmanager_secrets.db
      "/oracle/database/PPOASRP2" = local.secretsmanager_secrets.db
      "/oracle/database/PPOBODS4" = local.secretsmanager_secrets.db
      "/oracle/database/PPMISTN3" = local.secretsmanager_secrets.db # for AWS BODS testing
      "/oracle/database/PPOASRP3" = local.secretsmanager_secrets.db # for AWS BODS testing
      "/oracle/database/PPBOSYS"  = local.secretsmanager_secrets.db_bip
      "/oracle/database/PPBOAUD"  = local.secretsmanager_secrets.db_bip

      # for azure, remove when migrated to aws db
      "/oracle/database/OASPROD" = local.secretsmanager_secrets.db_oasys

      # for temporary use, remove when onr bip migrated to aws
      "/oracle/database/PPBISY42" = local.secretsmanager_secrets.bip
      "/oracle/database/PPBIAD42" = local.secretsmanager_secrets.bip
    }
  }
}
