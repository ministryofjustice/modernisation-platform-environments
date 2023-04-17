# nomis-test environment settings
locals {
  nomis_test = {
    # vars common across ec2 instances
    ec2_common = {
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    # cloud watch log groups
    log_groups = {
      session-manager-logs = {
        retention_days = 90
      }
      cwagent-var-log-messages = {
        retention_days = 30
      }
      cwagent-var-log-secure = {
        retention_days = 90
      }
      cwagent-nomis-autologoff = {
        retention_days = 90
      }
      cwagent-weblogic-logs = {
        retention_days = 30
      }
      cwagent-windows-system = {
        retention_days = 30
      }
    }

    # Add database instances here. They will be created using ec2-database.tf
    databases = {
      # Naming
      # *-nomis-db-1: NOMIS, NDH, TRDATA
      # *-nomis-db-2: MIS, AUDIT
      # *-nomis-db-3: HA
      t1-nomis-db-1 = {
        tags = {
          nomis-environment   = "t1"
          server-type         = "nomis-db"
          description         = "T1 NOMIS database"
          oracle-sids         = "CNOMT1"
          s3-db-restore-dir   = "CNOMT1_20230125"
          monitored           = true
          instance-scheduling = "skip-scheduling"
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          disable_api_termination = true
        }
        ebs_volumes = {
          "/dev/sdb" = { size = 100 }
          "/dev/sdc" = { size = 100 }
        }
        ebs_volume_config = {
          data  = { total_size = 100 }
          flash = { total_size = 50 }
        }
      }

      t1-nomis-db-1-a = {
        tags = {
          nomis-environment   = "t1"
          server-type         = "nomis-db"
          description         = "T1 NOMIS database"
          oracle-sids         = "CNOMT1"
          monitored           = true
          instance-scheduling = "skip-scheduling"
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2023-04-02T00-00-40.059Z"
        ami_owner = "self"
        instance = {
          disable_api_termination = true
        }
        ebs_volumes = {
          "/dev/sdb" = { size = 100 }
          "/dev/sdc" = { size = 100 }
        }
        ebs_volume_config = {
          data  = { total_size = 100 }
          flash = { total_size = 50 }
        }
      }

      t1-nomis-db-2 = {
        tags = {
          nomis-environment   = "t1"
          server-type         = "nomis-db"
          description         = "T1 NOMIS Audit database to replace Azure T1PDL0010"
          oracle-sids         = "T1CNMAUD"
          monitored           = true
          instance-scheduling = "skip-scheduling"
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          disable_api_termination = true
        }
        ebs_volumes = {
          "/dev/sdb" = { size = 100 }
          "/dev/sdc" = { size = 100 }
        }
        ebs_volume_config = {
          data  = { total_size = 200 }
          flash = { total_size = 2 }
        }
      }

      t3-nomis-db-1 = {
        tags = {
          nomis-environment   = "t3"
          server-type         = "nomis-db"
          description         = "T3 NOMIS database to replace Azure T3PDL0070"
          oracle-sids         = "T3CNOM"
          monitored           = true
          instance-scheduling = "skip-scheduling"
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          disable_api_termination = true
        }
        ebs_volumes = {
          "/dev/sdb" = { size = 100 }
          "/dev/sdc" = { size = 500 }
        }
        ebs_volume_config = {
          data  = { total_size = 2000 }
          flash = { total_size = 500 }
        }
      }
    }

    # Add weblogic instances here
    weblogic_autoscaling_groups = {
    }

    ec2_test_instances = {
      # Remove data.aws_kms_key from cmk.tf once the NDH servers are removed
    }

    ec2_test_autoscaling_groups = {}

    ec2_jumpservers = {
    }
  }

  # baseline config
  test_config = {


    baseline_acm_certificates = {
      nomis_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.${local.environment}.nomis.service.justice.gov.uk",
          "*.${local.environment}.nomis.az.justice.gov.uk",
          "*.hmpp-azdt.justice.gov.uk",
        ]
        cloudwatch_metric_alarms = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso"].acm_default
        tags = {
          description = "wildcard cert for nomis ${local.environment} domains"
        }
      }
    }


    baseline_ec2_autoscaling_groups = {
      t1-nomis-web-a = merge(local.ec2_weblogic_zone_a, {
        tags = merge(local.ec2_weblogic_zone_a.tags, {
          oracle-db-hostname = "t1-nomis-db-1"
          nomis-environment  = "t1"
          oracle-db-name     = "CNOMT1"
        })
        # autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      })
    }

    baseline_lbs = {
      # AWS doesn't let us call it internal
      private = {
        internal_lb              = true
        enable_delete_protection = false
        force_destroy_bucket     = true
        idle_timeout             = 3600
        public_subnets           = module.environment.subnets["private"].ids
        security_groups = [
          aws_security_group.public.id, # TODO: remove once weblogic servers refreshed
          "private-lb",
        ]

        listeners = {
          https = merge(
            local.lb_weblogic.https, {
              rules = {
                t1-nomis-web-a-http-7777 = {
                  priority = 300
                  actions = [{
                    type              = "forward"
                    target_group_name = "t1-nomis-web-a-http-7777"
                  }]
                  conditions = [{
                    host_header = {
                      values = [
                        "t1-nomis-web-a.test.nomis.az.justice.gov.uk",
                        "t1-nomis-web-a.test.nomis.service.justice.gov.uk",
                        "c-t1.test.nomis.az.justice.gov.uk",
                        "c-t1.test.nomis.service.justice.gov.uk",
                        "t1-cn.hmpp-azdt.justice.gov.uk",
                      ]
                    }
                  }]
                }
              }
          })
        }
      }
    }
    baseline_route53_zones = {
      "test.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
          { name = "t1-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "c-t1", type = "A", lbs_map_key = "private" },
        ]
      }
      "test.nomis.service.justice.gov.uk" = {
        records = [
          { name = "t1cnom-a", type = "A", ttl = "300", records = ["10.101.3.132"] },
          { name = "t1cnom-b", type = "A", ttl = "300", records = ["10.101.3.132"] },
        ]
        lb_alias_records = [
          { name = "t1-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "c-t1", type = "A", lbs_map_key = "private" },
        ]
      }
    }
  }
}
