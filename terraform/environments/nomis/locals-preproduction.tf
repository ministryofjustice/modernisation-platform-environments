# nomis-preproduction environment settings
locals {
  nomis_preproduction = {
    # account specific CIDRs for EC2 security groups
    external_database_access_cidrs = [
      local.cidrs.noms_live,
      local.cidrs.noms_mgmt_live,
      local.cidrs.noms_live_dr,
      local.cidrs.noms_mgmt_live_dr,
      local.cidrs.cloud_platform,
      local.cidrs.analytical_platform_airflow,
      local.cidrs.aks_studio_hosting_live_1,
      local.cidrs.nomisapi_preprod_root_vnet,
      local.cidrs.nomisapi_prod_root_vnet,
    ]
    external_oem_agent_access_cidrs = [
      local.cidrs.noms_live,
      local.cidrs.noms_mgmt_live,
      local.cidrs.noms_live_dr,
      local.cidrs.noms_mgmt_live_dr,
    ]
    external_remote_access_cidrs = [
      local.cidrs.noms_live,
      local.cidrs.noms_mgmt_live,
      local.cidrs.noms_live_dr,
      local.cidrs.noms_mgmt_live_dr,
    ]
    external_weblogic_access_cidrs = [
      local.cidrs.noms_live,
      local.cidrs.noms_mgmt_live,
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
    }
    weblogics       = {}
    ec2_jumpservers = {}
  }
}
