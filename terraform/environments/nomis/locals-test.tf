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
        ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-01-03T17-01-12.128Z"

        autoscaling_group = {
          desired_capacity = 1
          warm_pool        = null
        }
        autoscaling_schedules = {}
      }

      t1a-nomis-web = {
        tags = {
          ami                = "nomis_rhel_6_10_weblogic_appserver_10_3"
          description        = "T1 nomis weblogic 10.3 additional test scaling group"
          oracle-db-hostname = "t1-nomis-db-1"
          nomis-environment  = "t1"
          oracle-db-name     = "CNOMT1"
          server-type        = "nomis-web"
        }
        # ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-01-03T17-01-12.128Z"
        ami_name = "base_rhel_6_10_test_2022-12-30T16-10-33.253Z"
        user_data_cloud_init = {
          args = {
            lifecycle_hook_name  = "ready-hook"
            branch               = "nomis/weblogic-test-for-sandhya"
            ansible_repo         = "modernisation-platform-configuration-management"
            ansible_repo_basedir = "ansible"
            ansible_args         = "--tags ec2provision"
          }
        }
        autoscaling_group = {
          desired_capacity = 1
          warm_pool        = null
        }
        autoscaling_schedules = {}
        ebs_volumes = {
          "/dev/sdb" = {
            type = "gp3"
            size = 150
          }
        }
      }
    }

    ec2_test_instances = {
      # Remove data.aws_kms_key from cmk.tf once the NDH servers are removed
      t1-ndh-app-1 = {
        tags = {
          server-type       = "ndh-app"
          description       = "Standalone EC2 for testing RHEL7.9 NDH App"
          monitored         = false
          os-type           = "Linux"
          component         = "ndh"
          nomis-environment = "t1"
        }
        ebs_volumes = {
          "/dev/sda1" = { kms_key_id = data.aws_kms_key.default_ebs.arn }
        }
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
      }
      t1-ndh-ems-1 = {
        tags = {
          server-type       = "ndh-ems"
          description       = "Standalone EC2 for testing RHEL7.9 NDH EMS"
          monitored         = false
          os-type           = "Linux"
          component         = "ndh"
          nomis-environment = "t1"
        }
        ebs_volumes = {
          "/dev/sda1" = { kms_key_id = data.aws_kms_key.default_ebs.arn }
        }
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
      }
    }
    ec2_test_autoscaling_groups = {
      t1-ndh-app = {
        tags = {
          server-type       = "ndh-app"
          description       = "Standalone EC2 for testing RHEL7.9 NDH App"
          monitored         = false
          os-type           = "Linux"
          component         = "ndh"
          nomis-environment = "t1"
        }
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
        autoscaling_group = {
          desired_capacity = 1
        }
        autoscaling_schedules = {}
        subnet_name           = "data"
      }
      t1-ndh-ems = {
        tags = {
          server-type       = "ndh-ems"
          description       = "Standalone EC2 for testing RHEL7.9 NDH EMS"
          monitored         = false
          os-type           = "Linux"
          component         = "ndh"
          nomis-environment = "t1"
        }
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
        autoscaling_group = {
          desired_capacity = 1
        }
        autoscaling_schedules = {}
        subnet_name           = "data"
      }
    }
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
}
