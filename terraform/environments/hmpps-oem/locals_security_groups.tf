locals {

  security_group_cidrs_devtest = {
    oracle_db = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    oracle_oem_target_hosts = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    oracle_oem_console = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
  }
  security_group_cidrs_preprod_prod = {
    oracle_db = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    oracle_oem_target_hosts = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    oracle_oem_console = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
  }
  security_group_cidrs_by_environment = {
    development   = local.security_group_cidrs_devtest
    test          = local.security_group_cidrs_devtest
    preproduction = local.security_group_cidrs_preprod_prod
    production    = local.security_group_cidrs_preprod_prod
  }
  security_group_cidrs = local.security_group_cidrs_by_environment[local.environment]

  security_groups = {
    data-oem = {
      description = "Security group for OEM servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        ssh = {
          description = "Allow ssh ingress"
          from_port   = "22"
          to_port     = "22"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_oem_target_hosts
        }
        oracle1521 = {
          description = "Allow oracle database 1521 ingress"
          from_port   = "1521"
          to_port     = "1521"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_db
        }
        oracle3872 = {
          description = "Allow oem agent ingress"
          from_port   = "3872"
          to_port     = "3872"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_oem_target_hosts
        }
        oracle4903 = {
          description = "Allow oracle OEM https upload"
          from_port   = "4903"
          to_port     = "4903"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_oem_target_hosts
        }
        oracle7803 = {
          description = "Allow oracle OEM console"
          from_port   = "7803"
          to_port     = "7803"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_oem_console
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
          security_groups = []
        }
      }
    }
  }
}
