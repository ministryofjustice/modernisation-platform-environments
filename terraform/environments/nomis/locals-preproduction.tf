# nomis-preproduction environment settings
locals {
  nomis_preproduction = {
    # account specific CIDRs for EC2 security groups
    external_database_access_cidrs = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.azure_studio_hosting_cidrs.prod,
      module.ip_addresses.azure_nomisapi_cidrs.prod,
    ])
    external_oem_agent_access_cidrs = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
    ])
    external_remote_access_cidrs = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
    ])
    external_weblogic_access_cidrs = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
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

    databases_legacy = {}
    databases = {
      # Naming
      # *-nomis-db-1: NOMIS, NDH, TRDATA
      # *-nomis-db-2: MIS, AUDIT
      # *-nomis-db-3: HA
    }
    weblogics       = {}
    ec2_jumpservers = {}
  }
}
