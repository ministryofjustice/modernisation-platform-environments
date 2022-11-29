# nomis-test environment settings
locals {
  nomis_test = {
    # ip ranges for external access to database instances
    database_external_access_cidr = [
      local.cidrs.noms_test,
      local.cidrs.noms_mgmt,
      local.cidrs.cloud_platform
    ]

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
    }

    # Legacy database module, do not add any more entries here
    databases_legacy = {
      CNOMT1 = {
        ami_name           = "nomis_db_STIG_CNOMT1-2022-04-21*"
        asm_data_capacity  = 100
        asm_flash_capacity = 2
        description        = "Test NOMIS T1 database with a dataset of T1PDL0009 (note: only NOMIS db, NDH db is not included."
        tags = {
          monitored = false
        }
      }
    }

    # Add database instances here. They will be created using ec2-database.tf
    databases = {
      # Naming
      # *-nomis-db-1: NOMIS, NDH, TRDATA
      # *-nomis-db-2: MIS, AUDIT
      # *-nomis-db-3: HA

      t1-nomis-db-2 = {
        tags = {
          server-type         = "nomis-db"
          description         = "T1 NOMIS Audit database to replace Azure T1PDL0010"
          oracle-sids         = "T1CNMAUD"
          monitored           = false
          instance-scheduling = "skip-scheduling"
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          disable_api_termination = true
        }
        ebs_volumes = {
          "/dev/sdb" = { # /u01
            type = "gp3"
            size = 100
          }
          "/dev/sdc" = { # /u02
            type = "gp3"
            size = 100
          }
        }
        ebs_volume_config = {
          app = {
            type = "gp3"
          }
          data = {
            type       = "gp3"
            total_size = 200
          }
          flash = {
            type       = "gp3"
            total_size = 2
          }
          swap = {
            type = "gp3"
          }
        }
      }
    }

    # Add weblogic instances here
    weblogic_autoscaling_groups = {
      t1-nomis-web = {
        tags = {
          oracle-db-hostname = "db.CNOMT1.nomis.hmpps-test.modernisation-platform.internal"
          oracle-sid         = "CNOMT1"
        }
        ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2022-11-02T00-00-24.828Z"
        # branch = var.BRANCH_NAME # comment in if testing ansible

        # NOTE: setting desired capacity to 0 as this is not fully working yet
        # See DSOS-1570 and DSOS-1571
        autoscaling_group = {
          desired_capacity = 0
          warm_pool        = null
        }
        offpeak_desired_capacity = 0
      }
    }

    # Legacy weblogic, to be zapped imminently
    weblogics = {
      CNOMT1 = {
        ami_name     = "nomis_Weblogic_2022*"
        asg_max_size = 1
      }
    }

    ec2_test_instances = {
      t1-ndh-app-1 = {
        tags = {
          server-type = "ndh-app"
          description = "Standalone EC2 for testing RHEL7.9 NDH App"
        }
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
      t1-ndh-ems-1 = {
        tags = {
          server-type = "ndh-ems"
          description = "Standalone EC2 for testing RHEL7.9 NDH EMS"
        }
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
    }
    ec2_test_autoscaling_groups = {
      test-base-rhel79 = {
        tags = {
          ami         = "nomis_rhel_7_9_baseimage"
          description = "For testing our base RHEL7.9 base image"
          monitored   = false
        }
        ami_name = "nomis_rhel_7_9_baseimage*"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
      test-base-rhel610 = {
        tags = {
          ami         = "nomis_rhel_6_10_baseimage"
          description = "For testing our base RHEL6.10 base image"
          monitored   = false
        }
        instance = {
          instance_type                = "t2.medium"
          metadata_options_http_tokens = "optional"
        }
        ebs_volumes = {
          "/dev/sdb" = { # /u01
            type = "gp3"
            size = 150
          }
        }
        ami_name = "nomis_rhel_6_10_baseimage*"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
    }
    ec2_jumpserver_autoscaling_groups = {}
  }
}
