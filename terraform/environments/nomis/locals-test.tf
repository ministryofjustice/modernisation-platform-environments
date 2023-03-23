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
      t1-nomis-web = {
        tags = {
          ami                = "nomis_rhel_6_10_weblogic_appserver_10_3"
          description        = "T1 nomis weblogic 10.3"
          oracle-db-hostname = "t1-nomis-db-1"
          nomis-environment  = "t1"
          oracle-db-name     = "CNOMT1"
          server-type        = "nomis-web"
        }
        ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"

        autoscaling_group = {
          desired_capacity = 1
          warm_pool        = null
        }
        autoscaling_schedules = {}
      }
    }

    ec2_test_instances = {
      # Remove data.aws_kms_key from cmk.tf once the NDH servers are removed
    }

    ec2_test_autoscaling_groups = {}

    ec2_jumpservers = {
      jumpserver-2022 = {
        ami_name = "nomis_windows_server_2022_jumpserver_release_*"
        tags = {
          server-type       = "jumpserver"
          description       = "Windows Server 2022 Jumpserver for NOMIS"
          monitored         = false
          os-type           = "Windows"
          component         = "jumpserver"
          nomis-environment = "dev"
        }
        autoscaling_group = {
          min_size = 0
          max_size = 1
        }
      }
    }
  }

  # baseline config
  test_config = {
    baseline_lbs = {
      # AWS doesn't let us call it internal
      private = {
        internal_lb              = true
        enable_delete_protection = false
        existing_target_groups   = local.existing_target_groups
        force_destroy_bucket     = true
        idle_timeout             = 3600
        public_subnets           = module.environment.subnets["private"].ids
        security_groups          = [aws_security_group.public.id]

        listeners = {
          t1-nomis-web-http-7001 = merge(
            local.lb_weblogic.http-7001, {
              replace = {
                target_group_name_replace     = "t1-nomis-web"
                condition_host_header_replace = "t1-nomis-web"
              }
          })
          t1-nomis-web-http-7777 = merge(
            local.lb_weblogic.http-7777, {
              replace = {
                target_group_name_replace     = "t1-nomis-web"
                condition_host_header_replace = "t1-nomis-web"
              }
            }
          )
          t1-nomis-web-https = merge(
            local.lb_weblogic.https,
            local.lb_weblogic.route53, {
              replace = {
                target_group_name_replace     = "t1-nomis-web"
                condition_host_header_replace = "t1-nomis-web"
                route53_record_name_replace   = "t1-nomis-web"
              }
          })
        }

        # public LB not needed right now
        # public = {
        #   internal_lb              = false
        #   enable_delete_protection = false
        #   force_destroy_bucket     = true
        #   idle_timeout             = 3600
        #   public_subnets           = module.environment.subnets["public"].ids
        #   security_groups          = [aws_security_group.public.id]
        # }
      }
    }
  }
}
