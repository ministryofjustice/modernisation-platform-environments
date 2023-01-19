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
      # Naming
      # *-nomis-db-1: NOMIS, NDH, TRDATA
      # *-nomis-db-2: MIS, AUDIT
      # *-nomis-db-3: HA

      # add databases here as needed
    }
    weblogics          = {}
    ec2_test_instances = {}
    ec2_test_autoscaling_groups = {
      dev-redhat-rhel610 = {
        tags = {
          description = "For testing official RedHat RHEL6.10 image"
          monitored   = false
          os-type     = "Linux"
          component   = "test"
        }
        instance = {
          instance_type                = "t2.medium"
          metadata_options_http_tokens = "optional"
        }
        ami_name  = "RHEL-6.10_HVM-*"
        ami_owner = "309956199498"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
      dev-redhat-rhel79 = {
        tags = {
          description = "For testing official RedHat RHEL7.9 image"
          monitored   = false
          os-type     = "Linux"
          component   = "test"
        }
        ami_name  = "RHEL-7.9_HVM-*"
        ami_owner = "309956199498"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
      dev-base-rhel79 = {
        tags = {
          ami               = "base_rhel_7_9"
          description       = "For testing our base RHEL7.9 base image"
          monitored         = false
          os-type           = "Linux"
          component         = "test"
          nomis-environment = "dev"
          server-type       = "base-rhel79"
        }
        ami_name = "base_rhel_7_9_*"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
      dev-base-rhel610 = {
        tags = {
          ami               = "base_rhel_6_10"
          description       = "For testing our base RHEL6.10 base image"
          monitored         = false
          os-type           = "Linux"
          component         = "test"
          nomis-environment = "dev"
          server-type       = "base-rhel610"
        }
        instance = {
          instance_type                = "t2.medium"
          metadata_options_http_tokens = "optional"
        }
        ami_name = "base_rhel_6_10*"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
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
      jumpserver-2019 = {
        ami_name = "nomis_windows_server_2019_jumpserver_release_*"
        tags = {
          server-type       = "jumpserver"
          description       = "Windows Server 2019 Jumpserver for NOMIS"
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
