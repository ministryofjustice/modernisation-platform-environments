locals {

  lb_maintenance_message_development = {
    maintenance_title   = "Prison-NOMIS Maintenance Window"
    maintenance_message = "Prison-NOMIS is currently unavailable due to planned maintenance. Please try again later"
  }

  baseline_presets_development = {
    options = {
      sns_topics = {
        pagerduty_integrations = {
          dso_pagerduty               = "nomis_nonprod_alarms"
          dba_pagerduty               = "hmpps_shef_dba_non_prod"
          dba_high_priority_pagerduty = "hmpps_shef_dba_non_prod"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    acm_certificates = {
      nomis_wildcard_cert = {
        cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name              = "modernisation-platform.service.justice.gov.uk"
        subject_alternate_names = [
          "*.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk",
          "*.development.nomis.service.justice.gov.uk",
          "*.development.nomis.az.justice.gov.uk",
        ]
        tags = {
          description = "wildcard cert for nomis development domains"
        }
      }
    }

    ec2_autoscaling_groups = {
      dev-base-ol85 = {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          force_delete        = true
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = {
          "scale_up"   = { recurrence = "0 7 * * Mon-Fri" }
          "scale_down" = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
        }
        config = {
          ami_name                  = "base_ol_8_5*"
          iam_resource_names_prefix = "ec2-instance"
          instance_profile_policies = [
            # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
            "EC2Default",
            "EC2S3BucketWriteAndDeleteAccessPolicy",
            "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
          ]
          secretsmanager_secrets_prefix = "ec2/"
          ssm_parameters_prefix         = "ec2/"
          subnet_name                   = "private"
        }
        instance = {
          disable_api_termination      = false
          instance_type                = "t3.medium"
          key_name                     = "ec2-user"
          vpc_security_group_ids       = ["private-web"]
          metadata_options_http_tokens = "required"
          monitoring                   = false
        }
        user_data_cloud_init = {
          args = {
            lifecycle_hook_name  = "ready-hook"
            branch               = "main"
            ansible_repo         = "modernisation-platform-configuration-management"
            ansible_repo_basedir = "ansible"
            ansible_args         = "--tags ec2provision"
          }
          scripts = [
            "install-ssm-agent.sh.tftpl",
            "ansible-ec2provision.sh.tftpl",
            "post-ec2provision.sh.tftpl"
          ]
        }
        tags = {
          description = "For testing our base OL 8.5 base image"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-ol85"
        }
      }

      dev-base-rhel610 = {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          force_delete        = true
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = {
          "scale_up"   = { recurrence = "0 7 * * Mon-Fri" }
          "scale_down" = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
        }
        config = {
          ami_name                  = "base_rhel_6_10*"
          iam_resource_names_prefix = "ec2-instance"
          instance_profile_policies = [
            # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
            "EC2Default",
            "EC2S3BucketWriteAndDeleteAccessPolicy",
            "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
          ]
          secretsmanager_secrets_prefix = "ec2/"
          ssm_parameters_prefix         = "ec2/"
          subnet_name                   = "private"
        }
        instance = {
          disable_api_termination      = false
          instance_type                = "t2.medium"
          key_name                     = "ec2-user"
          vpc_security_group_ids       = ["private-web"]
          metadata_options_http_tokens = "optional"
          monitoring                   = false
        }
        user_data_cloud_init = {
          args = {
            lifecycle_hook_name  = "ready-hook"
            branch               = "main"
            ansible_repo         = "modernisation-platform-configuration-management"
            ansible_repo_basedir = "ansible"
            ansible_args         = "--tags ec2provision"
          }
          scripts = [
            "install-ssm-agent.sh.tftpl",
            "ansible-ec2provision.sh.tftpl",
            "post-ec2provision.sh.tftpl"
          ]
        }
        tags = {
          description = "For testing our base RHEL6.10 base image"
          ami         = "base_rhel_6_10"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-rhel610"
        }
      }

      dev-base-rhel79 = {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          force_delete        = true
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = {
          "scale_up"   = { recurrence = "0 7 * * Mon-Fri" }
          "scale_down" = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
        }
        config = {
          ami_name                  = "base_rhel_7_9_*"
          iam_resource_names_prefix = "ec2-instance"
          instance_profile_policies = [
            # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
            "EC2Default",
            "EC2S3BucketWriteAndDeleteAccessPolicy",
            "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
          ]
          secretsmanager_secrets_prefix = "ec2/"
          ssm_parameters_prefix         = "ec2/"
          subnet_name                   = "private"
        }
        instance = {
          disable_api_termination      = false
          instance_type                = "t3.medium"
          key_name                     = "ec2-user"
          vpc_security_group_ids       = ["private-web"]
          metadata_options_http_tokens = "required"
          monitoring                   = false
        }
        user_data_cloud_init = {
          args = {
            lifecycle_hook_name  = "ready-hook"
            branch               = "main"
            ansible_repo         = "modernisation-platform-configuration-management"
            ansible_repo_basedir = "ansible"
            ansible_args         = "--tags ec2provision"
          }
          scripts = [
            "install-ssm-agent.sh.tftpl",
            "ansible-ec2provision.sh.tftpl",
            "post-ec2provision.sh.tftpl"
          ]
        }
        tags = {
          description = "For testing our base RHEL7.9 base image"
          ami         = "base_rhel_7_9"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-rhel79"
        }
      }

      dev-base-rhel85 = {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          force_delete        = true
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = {
          "scale_up"   = { recurrence = "0 7 * * Mon-Fri" }
          "scale_down" = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
        }
        config = {
          ami_name                  = "base_rhel_8_5_*"
          iam_resource_names_prefix = "ec2-instance"
          instance_profile_policies = [
            # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
            "EC2Default",
            "EC2S3BucketWriteAndDeleteAccessPolicy",
            "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
          ]
          secretsmanager_secrets_prefix = "ec2/"
          ssm_parameters_prefix         = "ec2/"
          subnet_name                   = "private"
        }
        instance = {
          disable_api_termination      = false
          instance_type                = "t3.medium"
          key_name                     = "ec2-user"
          vpc_security_group_ids       = ["private-web"]
          metadata_options_http_tokens = "required"
          monitoring                   = false
        }
        user_data_cloud_init = {
          args = {
            lifecycle_hook_name  = "ready-hook"
            branch               = "main"
            ansible_repo         = "modernisation-platform-configuration-management"
            ansible_repo_basedir = "ansible"
            ansible_args         = "--tags ec2provision"
          }
          scripts = [
            "install-ssm-agent.sh.tftpl",
            "ansible-ec2provision.sh.tftpl",
            "post-ec2provision.sh.tftpl"
          ]
        }
        tags = {
          description = "For testing our base RHEL8.5 base image"
          ami         = "base_rhel_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-rhel85"
        }
      }

      dev-nomis-client-a = merge(local.ec2_autoscaling_groups.client, {
        tags = merge(local.ec2_autoscaling_groups.client.tags, {
          domain-name = "azure.noms.root"
        })
      })

      dev-nomis-web19c-a = merge(local.ec2_autoscaling_groups.web19c, {
      })

      dev-redhat-rhel79 = {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          force_delete        = true
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        autoscaling_schedules = {
          "scale_up"   = { recurrence = "0 7 * * Mon-Fri" }
          "scale_down" = { desired_capacity = 0, recurrence = "0 19 * * Mon-Fri" }
        }
        config = {
          ami_name                  = "hmpps_windows_server_2022_release_2024-*"
          ami_name                  = "RHEL-7.9_HVM-*"
          ami_owner                 = "309956199498"
          iam_resource_names_prefix = "ec2-instance"
          instance_profile_policies = [
            # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
            "EC2Default",
            "EC2S3BucketWriteAndDeleteAccessPolicy",
            "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
          ]
          secretsmanager_secrets_prefix = "ec2/"
          ssm_parameters_prefix         = "ec2/"
          subnet_name                   = "private"
        }
        instance = {
          disable_api_termination      = false
          instance_type                = "t3.medium"
          key_name                     = "ec2-user"
          vpc_security_group_ids       = ["private-web"]
          metadata_options_http_tokens = "required"
          monitoring                   = false
        }
        user_data_cloud_init = {
          args = {
            lifecycle_hook_name  = "ready-hook"
            branch               = "main"
            ansible_repo         = "modernisation-platform-configuration-management"
            ansible_repo_basedir = "ansible"
            ansible_args         = "--tags ec2provision"
          }
          scripts = [
            "install-ssm-agent.sh.tftpl",
            "ansible-ec2provision.sh.tftpl",
            "post-ec2provision.sh.tftpl"
          ]
        }
        tags = {
          description = "For testing official RedHat RHEL7.9 image"
          os-type     = "Linux"
          component   = "test"
        }
      }

    }

    ec2_instances = {
      dev-nomis-db-1-a = merge(local.ec2_instances.db, {
        config = merge(local.ec2_instances.db.config, {
          ami_name          = "nomis_rhel_7_9_oracledb_11_2_release_2023-07-02T00-00-39.521Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db.config.instance_profile_policies, [
            "Ec2DevDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.ec2_instances.db.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 50 }
        })
        instance = merge(local.ec2_instances.db.instance, {
          disable_api_termination = true
        })
        tags = merge(local.ec2_instances.db.tags, {
          nomis-environment   = "dev"
          description         = "syscon nomis dev and qa databases"
          instance-scheduling = "skip-scheduling"
          oracle-sids         = ""
        })
      })

      dev-nomis-db19c-1-a = merge(local.ec2_instances.db19c, {
        config = merge(local.ec2_instances.db19c.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_instances.db19c.config.instance_profile_policies, [
            "Ec2DevDatabasePolicy",
          ])
        })
        ebs_volumes = merge(local.ec2_instances.db19c.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.ec2_instances.db19c.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 50 }
        })
        instance = merge(local.ec2_instances.db19c.instance, {
          # disable_api_termination = true
        })
        user_data_cloud_init = merge(local.ec2_instances.db19c.user_data_cloud_init, {
          args = merge(local.ec2_instances.db19c.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_instances.db19c.tags, {
          nomis-environment   = "dev"
          description         = "syscon nomis dev and qa Oracle 19c databases"
          instance-scheduling = "skip-scheduling"
          oracle-sids         = ""
        })
      })

      dev-nomis-web-a = merge(local.ec2_autoscaling_groups.web, {
        cloudwatch_metric_alarms = {}
        config = merge(local.ec2_autoscaling_groups.web.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2DevWeblogicPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
          disable_api_termination = true
          instance_type           = "t2.large"
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          instance-scheduling  = "skip-scheduling"
          nomis-environment    = "dev"
          oracle-db-hostname-a = "dev-nomis-db-1-a"
          oracle-db-hostname-b = "none"
          oracle-db-name       = "dev"
        })
      })

      qa11g-nomis-web-a = merge(local.ec2_autoscaling_groups.web, {
        cloudwatch_metric_alarms = {}
        config = merge(local.ec2_autoscaling_groups.web.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2Qa11GWeblogicPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
          disable_api_termination = true
          instance_type           = "t2.large"
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          instance-scheduling  = "skip-scheduling"
          nomis-environment    = "qa11g"
          oracle-db-hostname-a = "dev-nomis-db-1-a"
          oracle-db-hostname-b = "none"
          oracle-db-name       = "qa11g"
        })
      })

      qa11r-nomis-web-a = merge(local.ec2_autoscaling_groups.web, {
        cloudwatch_metric_alarms = {}
        config = merge(local.ec2_autoscaling_groups.web.config, {
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2Qa11RWeblogicPolicy",
          ])
        })
        instance = merge(local.ec2_autoscaling_groups.web.instance, {
          disable_api_termination = true
          instance_type           = "t2.large"
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
        tags = merge(local.ec2_autoscaling_groups.web.tags, {
          instance-scheduling  = "skip-scheduling"
          nomis-environment    = "qa11r"
          oracle-db-hostname-a = "dev-nomis-db-1-a"
          oracle-db-hostname-b = "none"
          oracle-db-name       = "qa11r"
        })
      })

      dev-nomis-build-a = {
        cloudwatch_metric_alarms = {}
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_rhel_7_9_2024-03-01T00-00-34.773Z"
          availability_zone = "eu-west-2a"
          instance_profile_policies = concat(local.ec2_autoscaling_groups.web.config.instance_profile_policies, [
            "Ec2DevWeblogicPolicy",
            "Ec2Qa11GWeblogicPolicy",
            "Ec2Qa11RWeblogicPolicy",
          ])
        })
        ebs_volumes = {
          "/dev/sdb" = { label = "app", size = 100, type = "gp3" } # /u01
          "/dev/sdc" = { label = "app", size = 100, type = "gp3" } # /u02
        }
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          disable_api_termination = true
          instance_type           = "t3.medium"
          vpc_security_group_ids  = ["private-web"]
          tags = {
            backup-plan = "daily-and-weekly"
          }
        })
        route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        tags = {
          description         = "Syscon build and release server"
          ami                 = "base_rhel_7_9"
          instance-scheduling = "skip-scheduling"
          os-type             = "Linux"
          component           = "build"
          server-type         = "nomis-build"
        }
      }
    }

    iam_policies = {
      Ec2DevDatabasePolicy = {
        description = "Permissions required for Dev Database EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/dev/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/qa11g/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/qa11r/*",
            ]
          }
        ]
      }
      Ec2DevWeblogicPolicy = {
        description = "Permissions required for dev Weblogic EC2s"
        statements = concat(local.iam_policy_statements_ec2.web, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/dev/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/dev/weblogic-*",
            ]
          }
        ])
      }
      Ec2Qa11GWeblogicPolicy = {
        description = "Permissions required for QA11G Weblogic EC2s"
        statements = concat(local.iam_policy_statements_ec2.web, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/qa11g/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/qa11g/weblogic-*",
            ]
          }
        ])
      }
      Ec2Qa11RWeblogicPolicy = {
        description = "Permissions required for QA11R Weblogic EC2s"
        statements = concat(local.iam_policy_statements_ec2.web, [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/oracle/weblogic/qa11r/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/qa11r/weblogic-*",
            ]
          }
        ])
      }
    }

    lbs = {
      private = merge(local.lbs.private, {
        instance_target_groups = {
          dev-nomis-web-a-http-7777 = merge(local.ec2_autoscaling_groups.web.lb_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "dev-nomis-web-a" },
            ]
          })
          qa11g-nomis-web-a-http-7777 = merge(local.ec2_autoscaling_groups.web.lb_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "qa11g-nomis-web-a" },
            ]
          })
          qa11r-nomis-web-a-http-7777 = merge(local.ec2_autoscaling_groups.web.lb_target_groups.http-7777, {
            attachments = [
              { ec2_instance_name = "qa11r-nomis-web-a" },
            ]
          })
        }

        listeners = merge(local.lbs.private.listeners, {
          https = merge(local.lbs.private.listeners.https, {
            certificate_names_or_arns = ["nomis_wildcard_cert"]

            # /home/oracle/admin/scripts/lb_maintenance_mode.sh script on
            # weblogic servers can alter priorities to enable maintenance message
            rules = {
              dev-nomis-web-a-http-7777 = {
                priority = 100
                actions = [{
                  type              = "forward"
                  target_group_name = "dev-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "dev-nomis-web-a.development.nomis.service.justice.gov.uk",
                      "c-dev.development.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              qa11g-nomis-web-a-http-7777 = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "qa11g-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "qa11g-nomis-web-a.development.nomis.service.justice.gov.uk",
                      "c-qa11g.development.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              qa11r-nomis-web-a-http-7777 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "qa11r-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "qa11r-nomis-web-a.development.nomis.service.justice.gov.uk",
                      "c-qa11r.development.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              maintenance = {
                priority = 999
                actions = [{
                  type = "fixed-response"
                  fixed_response = {
                    content_type = "text/html"
                    message_body = templatefile("templates/maintenance.html.tftpl", local.lb_maintenance_message_development)
                    status_code  = "200"
                  }
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "maintenance.development.nomis.service.justice.gov.uk",
                      "c-dev.development.nomis.service.justice.gov.uk",
                      "c-qa11g.development.nomis.service.justice.gov.uk",
                      "c-qa11r.development.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        })
      })
    }

    route53_zones = {
      "development.hmpps-test.modernisation-platform.service.justice.gov.uk" = {
        records = [
        ]
      }
      "development.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
        ]
      }
      "development.nomis.service.justice.gov.uk" = {
        records = [
          # SYSCON
          { name = "dev", type = "CNAME", ttl = "300", records = ["dev-nomis-db-1-a.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk"] },
          { name = "qa11g", type = "CNAME", ttl = "300", records = ["dev-nomis-db-1-a.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk"] },
          { name = "qa11r", type = "CNAME", ttl = "300", records = ["dev-nomis-db-1-a.nomis.hmpps-development.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          { name = "maintenance", type = "A", lbs_map_key = "private" },
          # dev
          { name = "dev-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "dev-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-dev", type = "A", lbs_map_key = "private" },
          # qa11g
          { name = "qa11g-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "qa11g-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-qa11g", type = "A", lbs_map_key = "private" },
          # qa11r
          { name = "qa11r-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "qa11r-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-qa11r", type = "A", lbs_map_key = "private" },
        ]
      }
    }

    s3_buckets = {
      nomis-audit-archives = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
      nomis-db-backup-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
      s3-bucket = {
        iam_policies = module.baseline_presets.s3_iam_policies
      }
      syscon-bucket = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        iam_policies   = module.baseline_presets.s3_iam_policies
      }
    }

    secretsmanager_secrets = {
      "/oracle/weblogic/dev"   = local.secretsmanager_secrets.web
      "/oracle/database/dev"   = local.secretsmanager_secrets.db_cnom
      "/oracle/weblogic/qa11g" = local.secretsmanager_secrets.web
      "/oracle/database/qa11g" = local.secretsmanager_secrets.db_cnom
      "/oracle/weblogic/qa11r" = local.secretsmanager_secrets.web
      "/oracle/database/qa11r" = local.secretsmanager_secrets.db_cnom
    }
  }
}
