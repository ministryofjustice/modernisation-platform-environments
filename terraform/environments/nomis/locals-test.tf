# nomis-test environment settings
locals {
  nomis_test = {
    # account specific CIDRs for EC2 security groups
    external_database_access_cidrs = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.azure_studio_hosting_cidrs.devtest,
      module.ip_addresses.azure_nomisapi_cidrs.devtest,
    ])
    external_oem_agent_access_cidrs = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
    ])
    external_remote_access_cidrs = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
    ])
    external_weblogic_access_cidrs = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress
    ])

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
          monitored   = false
          oracle-sids = "CNOMT1"
        }
      }
    }

    # Add database instances here. They will be created using ec2-database.tf
    databases = {
      # Naming
      # *-nomis-db-1: NOMIS, NDH, TRDATA
      # *-nomis-db-2: MIS, AUDIT
      # *-nomis-db-3: HA

      t1-nomis-db-2 = {
        tags = {
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

      t3-nomis-db-1 = {
        tags = {
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
          "/dev/sdb" = { # /u01
            type = "gp3"
            size = 100
          }
          "/dev/sdc" = { # /u02
            type = "gp3"
            size = 500
          }
        }
        ebs_volume_config = {
          app = {
            type = "gp3"
          }
          data = {
            type       = "gp3"
            total_size = 2000
          }
          flash = {
            type       = "gp3"
            total_size = 500
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
          ami                = "nomis_rhel_6_10_weblogic_appserver_10_3"
          description        = "T1 nomis weblogic 10.3"
          oracle-db-hostname = "db.CNOMT1.nomis.hmpps-test.modernisation-platform.internal"
          nomis-environment  = "t1"
          oracle-db-name     = "CNOMT1"
          server-type        = "nomis-web"
        }
        ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-01-03T17-01-12.128Z"
        branch   = var.BRANCH_NAME # comment in if testing ansible

        autoscaling_group = {
          desired_capacity = 1
          warm_pool        = null
          target_group_arns = local.environment == "test" ? [
            module.lb_listener["https"].aws_lb_target_group["http-7001-asg"].arn,
            module.lb_listener["https"].aws_lb_target_group["http-7777-asg"].arn,
            module.lb_listener["http-7001"].aws_lb_target_group["http-7001-asg"].arn,
            module.lb_listener["http-7777"].aws_lb_target_group["http-7777-asg"].arn,
            module.lb_listener["internal-https"].aws_lb_target_group["http-7001-asg"].arn,
            module.lb_listener["internal-https"].aws_lb_target_group["http-7777-asg"].arn,
            module.lb_listener["internal-http-7001"].aws_lb_target_group["http-7001-asg"].arn,
            module.lb_listener["internal-http-7777"].aws_lb_target_group["http-7777-asg"].arn,
          ] : []
        }
      }
    }

    ec2_test_instances = {
      t1-nomis-web-1 = {
        tags = {
          ami                = "nomis_rhel_6_10_weblogic_appserver_10_3"
          description        = "For testing our RHEL6.10 weblogic image"
          monitored          = false
          os-type            = "Linux"
          component          = "web"
          server-type        = "nomis-web"
          oracle-db-hostname = "db.CNOMT1.nomis.hmpps-test.modernisation-platform.internal"
          oracle-db-name     = "CNOMT1"
        }
        instance = {
          # set to large for weblogic testing
          instance_type                = "t2.large"
          metadata_options_http_tokens = "optional"
          associate_public_ip_address  = true
          ebs_block_device_inline      = true
        }
        ebs_volumes = {
          "/dev/sdb" = { # /u01 (add for weblogic testing)
            type       = "gp3"
            size       = 150
            kms_key_id = module.environment.kms_keys["general"].arn
          }
        }
        route53_records = {
          create_internal_record = true
          create_external_record = true
        }
        subnet_name = "public"
        ami_name    = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-01-03T17-01-12.128Z"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
      t1-ndh-app-1 = {
        tags = {
          server-type       = "ndh-app"
          description       = "Standalone EC2 for testing RHEL7.9 NDH App"
          monitored         = false
          os-type           = "Linux"
          component         = "ndh"
          nomis-environment = "t1"
        }
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
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
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
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
        # branch   = var.BRANCH_NAME # comment in if testing ansible
        autoscaling_group = {
          desired_capacity = 0
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
        # branch   = var.BRANCH_NAME # comment in if testing ansible
        autoscaling_group = {
          desired_capacity = 0
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
          monitored         = true
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
