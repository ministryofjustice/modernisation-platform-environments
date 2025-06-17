locals {

  security_group_cidrs_devtest = {
    core = module.ip_addresses.azure_fixngo_cidrs.devtest_core
    enduserclient = [
      "10.0.0.0/8"
    ]
    domain_controllers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest_domain_controllers,
      module.ip_addresses.mp_cidrs.ad_fixngo_azure_domain_controllers,
    ])
    # consolodate below in future PR
    jumpservers = module.ip_addresses.azure_fixngo_cidrs.devtest_jumpservers
    jumpservers2 = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest_jumpservers,
      module.ip_addresses.mp_cidr[module.environment.vpc_name]
    ])
    remotedesktop_gateways = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest_jumpservers,
      module.ip_addresses.mp_cidr[module.environment.vpc_name]
    ])
    remotedesktop_connectionbrokers = [module.ip_addresses.mp_cidr[module.environment.vpc_name]]
  }

  security_group_cidrs_preprod_prod = {
    core = module.ip_addresses.azure_fixngo_cidrs.prod_core
    enduserclient = [
      "10.0.0.0/8"
    ]
    domain_controllers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod_domain_controllers,
      # module.ip_addresses.mp_cidrs.ad_fixngo_hmpp_domain_controllers, # hits rule limit, remove azure DCs first
    ])
    # consolodate below in future PR
    jumpservers = module.ip_addresses.azure_fixngo_cidrs.prod_jumpservers
    jumpservers2 = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod_jumpservers,
      module.ip_addresses.mp_cidr[module.environment.vpc_name]
    ])
    remotedesktop_gateways = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod_jumpservers,
      module.ip_addresses.mp_cidr[module.environment.vpc_name]
    ])
    remotedesktop_connectionbrokers = [module.ip_addresses.mp_cidr[module.environment.vpc_name]]
  }

  security_group_cidrs_by_environment = {
    development   = local.security_group_cidrs_devtest
    test          = local.security_group_cidrs_devtest
    preproduction = local.security_group_cidrs_preprod_prod
    production    = local.security_group_cidrs_preprod_prod
  }

  security_group_cidrs = local.security_group_cidrs_by_environment[local.environment]

  security_groups = {
    loadbalancer = {
      description = "PlanetFM loadbalancer SG"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http_lb = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        https_lb = {
          description = "Allow enduserclient https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
      }
      egress = {
        all = {
          description = "Allow all traffic outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    web = {
      description = "Security group for Windows Web Servers"
      ingress = {
        http_web = {
          description     = "80: Allow HTTP ingress from LB"
          from_port       = 80
          to_port         = 80
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.jumpserver2
          security_groups = ["loadbalancer"]
        }
        https_web = {
          description = "443: Allow HTTPS ingress from Azure"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
      }
    }
    app = {
      description = "Security group for Windows App Servers"
      ingress = {
        all-from-web = {
          description     = "Allow all ingress from web"
          from_port       = 0
          to_port         = 0
          protocol        = -1
          security_groups = ["web"]
        }
        web_access_cafm_5504 = {
          description     = "All web access inbound on 5504"
          from_port       = 5504
          to_port         = 5504
          protocol        = "TCP"
          security_groups = ["database", "loadbalancer"]
          cidr_blocks     = local.security_group_cidrs.enduserclient
        }
        cafm_licensing_7071 = {
          description = "All CAFM licensing inbound on 7071"
          from_port   = 7071
          to_port     = 7071
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        cafm_licensing_7073 = {
          description = "All CAFM licensing inbound on 7073"
          from_port   = 7073
          to_port     = 7073
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
      }
    }
    domain = {
      description = "Common Windows security group for fixngo domain(s) access from Jumpservers and Azure DCs"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        rpc_udp_domain = {
          description = "135: UDP MS-RPC AD connect ingress from Azure DC"
          from_port   = 135
          to_port     = 135
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        rpc_tcp_domain = {
          description = "135: TCP MS-RPC AD connect ingress from Azure DC"
          from_port   = 135
          to_port     = 135
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        netbios_tcp_domain = {
          description = "137-139: TCP NetBIOS ingress from Azure DC"
          from_port   = 137
          to_port     = 139
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        netbios_udp_domain = {
          description = "137-139: UDP NetBIOS ingress from Azure DC"
          from_port   = 137
          to_port     = 139
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        ldap_tcp_domain = {
          description = "389: TCP Allow LDAP ingress from Azure DC"
          from_port   = 389
          to_port     = 389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
          # NOTE: not completely clear this is needed as it's not in the existing Azure SG's
        }
        ldap_udp_domain = {
          description = "389: UDP Allow LDAP ingress from Azure DC"
          from_port   = 389
          to_port     = 389
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
          # NOTE: not completely clear this is needed as it's not in the existing Azure SG's
        }

        smb_tcp_domain = {
          description = "445: TCP SMB ingress from Azure DC"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        smb_udp_domain = {
          description = "445: UDP SMB ingress from Azure DC"
          from_port   = 445
          to_port     = 445
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        rpc_dynamic_udp_domain = {
          description = "49152-65535: UDP Dynamic Port range"
          from_port   = 49152
          to_port     = 65535
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        rpc_dynamic_tcp_domain = {
          description = "49152-65535: TCP Dynamic Port range"
          from_port   = 49152
          to_port     = 65535
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
      }
      egress = {
        all = {
          description = "Allow all traffic outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    remotedesktop_sessionhost = {
      description = "Security group required for AWS remote desktop solution"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        rpc_udp_remotedesktop = {
          description = "135: TCP RPC ingress for remote management"
          from_port   = 135
          to_port     = 135
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.remotedesktop_connectionbrokers
        }
        rpc_tcp_remotedesktop = {
          description = "135: TCP RPC ingress for remote management"
          from_port   = 135
          to_port     = 135
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.remotedesktop_connectionbrokers
        }
        smb_tcp_remotedesktop = {
          description = "445: TCP SMB ingress for remote management"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.remotedesktop_connectionbrokers
        }
        smb_udp_remotedesktop = {
          description = "445: UDP SMB ingress for remote management"
          from_port   = 445
          to_port     = 445
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.remotedesktop_connectionbrokers
        }
        winrm_tcp_remotedesktop = {
          description = "5985: TCP WinRM ingress for remote management"
          from_port   = 5985
          to_port     = 5986
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.remotedesktop_connectionbrokers
        }
        rpc_dynamic_udp_remotedesktop = {
          description = "49152-65535: UDP Dynamic Port ingress for remote management"
          from_port   = 49152
          to_port     = 65535
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.remotedesktop_connectionbrokers
        }
        rpc_dynamic_tcp_remotedesktop = {
          description = "49152-65535: TCP Dynamic Port ingress for remote management"
          from_port   = 49152
          to_port     = 65535
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.remotedesktop_connectionbrokers
        }
      }
      egress = {
        all = {
          description = "Allow all traffic outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    jumpserver = {
      description = "New security group for jump-servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        rpc_udp_jumpserver = {
          description = "135: UDP MS-RPC AD connect ingress from Azure Jumpservers"
          from_port   = 135
          to_port     = 135
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        rpc_tcp_jumpserver = {
          description = "135: TCP MS-RPC AD connect ingress from Azure Jumpservers"
          from_port   = 135
          to_port     = 135
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        netbios_tcp_jumpserver = {
          description = "137-139: TCP NetBIOS ingress from Azure Jumpservers"
          from_port   = 137
          to_port     = 139
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        netbios_udp_jumpserver = {
          description = "137-139: UDP NetBIOS ingress from Azure Jumpservers"
          from_port   = 137
          to_port     = 139
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        ldap_tcp_jumpserver = {
          description = "389: TCP Allow LDAP ingress from Azure Jumpservers"
          from_port   = 389
          to_port     = 389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
          # NOTE: not completely clear this is needed as it's not in the existing Azure SG's
        }
        ldap_udp_jumpserver = {
          description = "389: UDP Allow LDAP ingress from Azure Jumpservers"
          from_port   = 389
          to_port     = 389
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.jumpservers
          # NOTE: not completely clear this is needed as it's not in the existing Azure SG's
        }
        smb_tcp_jumpserver = {
          description = "445: TCP SMB ingress from Azure Jumpservers"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        smb_udp_jumpserver = {
          description = "445: UDP SMB ingress from Azure Jumpservers"
          from_port   = 445
          to_port     = 445
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        winrm_tcp_jumpserver = {
          description = "5985: TCP WinRM ingress from Azure Jumpservers"
          from_port   = 5985
          to_port     = 5986
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        rpc_dynamic_udp_jumpserver = {
          description = "49152-65535: UDP Dynamic Port rang from Azure Jumpservers"
          from_port   = 49152
          to_port     = 65535
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        rpc_dynamic_tcp_jumpserver = {
          description = "49152-65535: TCP Dynamic Port range from Azure Jumpservers"
          from_port   = 49152
          to_port     = 65535
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
      }
      egress = {
        all = {
          description = "Allow all traffic outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    database = {
      description = "Security group for WINDOWS SQL database servers"
      ingress = {
        all-from-app = {
          description     = "Allow all ingress from app"
          from_port       = 0
          to_port         = 0
          protocol        = -1
          security_groups = ["app"]
        }
        all-from-web = {
          description     = "Allow all ingress from web"
          from_port       = 0
          to_port         = 0
          protocol        = -1
          security_groups = ["web"]
        }
        http_enduser_db = {
          description = "80: HTTP ingress for end-users"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        netbios_tcp_enduser = {
          description = "137-139: TCP NetBIOS ingress from enduserclient"
          from_port   = 137
          to_port     = 139
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        netbios_udp_enduser = {
          description = "137-139: UDP NetBIOS ingress from enduserclient"
          from_port   = 137
          to_port     = 139
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        smb_tcp_445_enduser = {
          description = "445: TCP SMB ingress from enduserclient"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        sql_tcp_1433_enduser = {
          description = "1433: Allow SQL Server TCP ingress from enduserclient for authentication"
          from_port   = 1433
          to_port     = 1433
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        sql_udp_1434_enduser = {
          description = "1434: Allow SQL Server UDP ingress from enduserclient for authentication"
          from_port   = 1434
          to_port     = 1434
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        cafm_licensing_7071_db = {
          description = "7071: All CAFM licensing inbound"
          from_port   = 7071
          to_port     = 7071
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        cafm_licensing_db = {
          description = "7073: All CAFM licensing inbound"
          from_port   = 7073
          to_port     = 7073
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        rpc_dynamic_tcp_db = {
          description = "49152-65535: TCP Dynamic Port range"
          from_port   = 49152
          to_port     = 65535
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
      }
    }
  }
}
