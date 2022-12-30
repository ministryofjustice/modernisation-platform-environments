# nomis-development environment settings
locals {
  nomis_development = {
    # account specific CIDRs for EC2 security groups
    external_database_access_cidrs = [
      local.cidrs.noms_test,
      local.cidrs.noms_mgmt,
      local.cidrs.noms_test_dr,
      local.cidrs.noms_mgmt_dr,
      local.cidrs.cloud_platform,
      local.cidrs.analytical_platform_airflow,
      local.cidrs.aks_studio_hosting_dev_1,
      local.cidrs.nomisapi_t3_root_vnet,
    ]
    external_oem_agent_access_cidrs = [
      local.cidrs.noms_test,
      local.cidrs.noms_mgmt,
      local.cidrs.noms_test_dr,
      local.cidrs.noms_mgmt_dr,
    ]
    external_remote_access_cidrs = [
      local.cidrs.noms_test,
      local.cidrs.noms_mgmt,
      local.cidrs.noms_test_dr,
      local.cidrs.noms_mgmt_dr,
    ]
    external_weblogic_access_cidrs = [
      local.cidrs.noms_test,
      local.cidrs.noms_mgmt,
      local.cidrs.noms_transit_live_fw_devtest,
      local.cidrs.noms_transit_live_fw_prod,
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

    databases_legacy = {}
    databases = {
      # Naming
      # *-nomis-db-1: NOMIS, NDH, TRDATA
      # *-nomis-db-2: MIS, AUDIT
      # *-nomis-db-3: HA

      # For ad-hoc testing.  Comment in and out as needed
      #      dev-nomis-db-1 = {
      #        tags = {
      #          server-type       = "nomis-db"
      #          description       = "Dev database using T1 data set"
      #          oracle-sids       = "CNOMT1"
      #          monitored         = false
      #          s3-db-restore-dir = "CNOMT1_20211214"
      #        }
      #        ami_name  = "nomis_rhel_7_9_oracledb_11_2_*"
      #        ami_owner = "self"
      #        ebs_volume_config = {
      #          app = {
      #            iops       = 300   # Temporary. See DSOS-1561
      #            throughput = 0     # Temporary. See DSOS-1561
      #            type       = "gp2" # Temporary. See DSOS-1561
      #          }
      #          data = {
      #            iops       = 120   # Temporary. See DSOS-1561
      #            throughput = 0     # Temporary. See DSOS-1561
      #            type       = "gp2" # Temporary. See DSOS-1561
      #            total_size = 200
      #          }
      #          flash = {
      #            iops       = 100   # Temporary. See DSOS-1561
      #            throughput = 0     # Temporary. See DSOS-1561
      #            type       = "gp2" # Temporary. See DSOS-1561
      #            total_size = 2
      #          }
      #          swap = {
      #            iops       = 100   # Temporary. See DSOS-1561
      #            throughput = 0     # Temporary. See DSOS-1561
      #            type       = "gp2" # Temporary. See DSOS-1561
      #          }
      #        }
      #        # branch = var.BRANCH_NAME # comment in if testing ansible
      #      }
    }
    weblogics          = {}
    ec2_test_instances = {}
    ec2_test_autoscaling_groups = {
      dev-redhat-rhel79 = {
        tags = {
          description       = "For testing official RedHat RHEL7.9 base image"
          server-type       = "base-rhel79"
          monitored         = false
          nomis-environment = "dev"
        }
        ami_name  = "RHEL-7.9_HVM-*"
        ami_owner = "309956199498"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
      dev-base-rhel79 = {
        tags = {
          ami               = "nomis_rhel_7_9_baseimage"
          description       = "For testing our base RHEL7.9 base image"
          monitored         = false
          nomis-environment = "dev"
          server-type       = "base-rhel79"
        }
        ami_name = "nomis_rhel_7_9_baseimage*"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
      dev-base-rhel610 = {
        tags = {
          ami               = "nomis_rhel_6_10_baseimage"
          description       = "For testing our base RHEL6.10 base image"
          monitored         = false
          nomis-environment = "dev"
          server-type       = "base-rhel610"
        }
        instance = {
          instance_type                = "t2.medium"
          metadata_options_http_tokens = "optional"
        }
        ami_name = "nomis_rhel_6_10_baseimage*"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
    }
    ec2_jumpservers = {
      jumpserver-2022 = {
        ami_name = "nomis_windows_server_2022_jumpserver_2022*"
        tags = {
          server-type       = "jumpserver"
          description       = "Windows Server 2022 Jumpserver for NOMIS"
          nomis-environment = "jumpserver"
        }
        autoscaling_group = {
          min_size = 0
          max_size = 1
        }
      }
    }
  }
}
