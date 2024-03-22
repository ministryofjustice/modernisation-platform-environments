locals {
  security_group_cidrs_devtest = {
    aks       = module.ip_addresses.azure_fixngo_cidrs.devtest
    boe_tools = module.ip_addresses.azure_fixngo_cidrs.devtest_tools
    domain_controllers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest_domain_controllers,
      module.ip_addresses.mp_cidrs.ad_fixngo_azure_domain_controllers,
    ])
    jumpservers = module.ip_addresses.azure_fixngo_cidrs.devtest_jumpservers
    noms_core   = module.ip_addresses.azure_fixngo_cidrs.devtest_core
    oasys_db = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      module.ip_addresses.azure_fixngo_cidrs.devtest_oasys_db,
    ])
  }

  security_group_cidrs_preprod_prod = {
    aks       = module.ip_addresses.azure_fixngo_cidrs.prod
    boe_tools = module.ip_addresses.azure_fixngo_cidrs.prod_tools
    domain_controllers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod_domain_controllers,
      # module.ip_addresses.mp_cidrs.ad_fixngo_hmpp_domain_controllers, # hits rule limit, remove azure DCs first
    ])
    jumpservers = module.ip_addresses.azure_fixngo_cidrs.prod_jumpservers
    noms_core   = module.ip_addresses.azure_fixngo_cidrs.prod_core
    oasys_db = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      module.ip_addresses.azure_fixngo_cidrs.prod_oasys_db,
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
    # TODO: PLACEHOLDER FOR LOADBALANCER SG - NOT YET DEPLOYED/USED
    # loadbalancer = {
    #     description = "Security group for load balancer"
    #     ingress = {
    #         all-from-self = {
    #             description = "Allow all ingress to self"
    #             from_port   = 0
    #             to_port     = 0
    #             protocol    = -1
    #             self        = true
    #         }
    #     }
    #     egress = {
    #         all = {
    #             description = "Allow all traffic outbound"
    #             from_port   = 0
    #             to_port     = 0
    #             protocol    = "-1"
    #             cidr_blocks = ["0.0.0.0/0"]
    #         }
    #     }
    # }
    # TODO: PLACEHOLDER FOR WEB SG - NOT YET DEPLOYED/USED
    web = {
      description = "Security group for web servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        echo_tcp_web = {
          description = "7: Allow echo traffic to web servers"
          from_port   = 7
          to_port     = 7
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.noms_core
        }
        echo_udp_web = {
          description = "7: Allow echo traffic to web servers"
          from_port   = 7
          to_port     = 7
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.noms_core
        }
        ssh_web = {
          description = "22: Allow ssh traffic to web servers"
          from_port   = 22
          to_port     = 22
          protocol    = "TCP"
          cidr_blocks = concat(local.security_group_cidrs.jumpservers, local.security_group_cidrs.aks, local.security_group_cidrs.noms_core)
        }
        rpc_tcp_web = {
          description = "135: TCP MS-RPC AD connect ingress from Jumpservers"
          from_port   = 135
          to_port     = 135
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        rpc_udp_web = {
          description = "135: UDP MS-RPC AD connect ingress from Jumpservers"
          from_port   = 135
          to_port     = 135
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        oracle_oem_web_3872 = {
          description = "3872: oracle oem agent from noms_core"
          from_port   = 3872
          to_port     = 3872
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.noms_core
        }
        oracle_oem_web_4983 = {
          description = "4983: oracle oem agent from noms_core"
          from_port   = 4983
          to_port     = 4983
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.noms_core
        }
        weblogic_node_manager_web = {
          description = "5556: weblogic node manager from noms_core"
          from_port   = 5556
          to_port     = 5556
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.noms_core
        }
        weblogic_admin = {
          description = "7001: Weblogic admin port"
          from_port   = 7001
          to_port     = 7001
          protocol    = "TCP"
          cidr_blocks = concat(local.security_group_cidrs.jumpservers, local.security_group_cidrs.noms_core)
        }
        oracle_weblogic_admin = {
          description = "7001: Weblogic admin port from Jumpservers and AKS"
          from_port   = 7777
          to_port     = 7777
          protocol    = "TCP"
          cidr_blocks = concat(local.security_group_cidrs.jumpservers, local.security_group_cidrs.aks, local.security_group_cidrs.noms_core)
          # TODO: security_groups = ["loadbalancer"] # <= add later!
        }
        http_web = {
          description = "8080: Allow HTTP ingress from Jumpservers and AKS"
          from_port   = 8080
          to_port     = 8080
          protocol    = "TCP"
          cidr_blocks = concat(local.security_group_cidrs.jumpservers, local.security_group_cidrs.aks)
          # TODO: security_groups = ["loadbalancer"] # <= add later!
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

    boe = {
      description = "Security group for Windows App Servers"
      ingress = {
        all-from-self = {
          description     = "Allow all ingress to self"
          from_port       = 0
          to_port         = 0
          protocol        = -1
          self            = true
          security_groups = ["web"]
        }
        boe_cms = {
          description = "6400: BOE CMS management in from jumpservers"
          from_port   = 6400
          to_port     = 6400
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        boe_sia = {
          description = "6410-6500: BOE SIA range in from jumpservers"
          from_port   = 6410
          to_port     = 6500
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers

        }
        weblogic_admin = {
          description = "7001: Weblogic admin in from jumpservers"
          from_port   = 7001
          to_port     = 7001
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        oracle_bi = {
          description = "9704: Oracle BI in from jumpservers"
          from_port   = 9704
          to_port     = 9704
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        webadmin_http = {
          description = "28080: Web admin http in from jumpservers"
          from_port   = 28080
          to_port     = 28080
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

    bods = {
      description = "Security group for BODS servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
          # TODO: security_groups = ["onr_db"] ONR DB NOT YET DEPLOYED
        }
        bods_boe_cms = {
          description = "6400: BOE CMS management in from jumpservers"
          from_port   = 6400
          to_port     = 6400
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        bods_boe_sia = {
          description = "6410-6500: BOE SIA range in from jumpservers"
          from_port   = 6410
          to_port     = 6500
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers

        }
        bods_weblogic_admin = {
          description = "7001: Weblogic admin in from jumpservers"
          from_port   = 7001
          to_port     = 7001
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        bods_oracle_bi = {
          description = "9704: Oracle BI in from jumpservers"
          from_port   = 9704
          to_port     = 9704
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        bods_webadmin_http = {
          description = "28080: Web admin http in from jumpservers"
          from_port   = 28080
          to_port     = 28080
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
    # TODO: PLACEHOLDER FOR DATABASE SERVER - NOT YET DEPLOYED/USED
    # onr_db = {}
    aks = {
      description = "Common security group for AKS ingress"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        ssh_aks = {
          description = "22: Allow ssh traffic to web servers"
          from_port   = 22
          to_port     = 22
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.aks
        }
        winrm_https_aks = {
          description = "5985: Allow winrm https traffic to web servers"
          from_port   = 5986
          to_port     = 5986
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.aks
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
    boe_tools = {
      description = "Common security group for BOE Tools"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        boe_tools_cms = {
          description = "6400: Allow BOE CMS traffic from noms mgmt tools"
          from_port   = 6400
          to_port     = 6400
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.boe_tools
        }
        boe_tools_sia = {
          description = "6410-6500: Allow BOE SIA range traffic from noms mgmt tools"
          from_port   = 6410
          to_port     = 6500
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.boe_tools
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
    domain = {
      description = "Security group in from Domain Controllers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        rpc_tcp_domain = {
          description = "135: TCP MS-RPC AD connect ingress from Domain Controllers"
          from_port   = 135
          to_port     = 135
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        rpc_udp_domain = {
          description = "135: UDP MS-RPC AD connect ingress from Domain Controllers"
          from_port   = 135
          to_port     = 135
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        netbios_tcp_domain = {
          description = "137-139: TCP NetBIOS ingress from Domain Controllers"
          from_port   = 137
          to_port     = 139
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        netbios_udp_domain = {
          description = "137-139: UDP NetBIOS ingress from Domain Controllers"
          from_port   = 137
          to_port     = 139
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        smb_tcp_domain = {
          description = "445: TCP SMB ingress from Domain Controllers"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        smb_udp_domain = {
          description = "445: UDP SMB ingress from Domain Controllers"
          from_port   = 445
          to_port     = 445
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        rpc_dynamic_tcp_domain = {
          description = "49152-65535: TCP Dynamic Port range from Domain Controllers"
          from_port   = 49152
          to_port     = 65535
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.domain_controllers
        }
        rpc_dynamic_udp_domain = {
          description = "49152-65535: UDP Dynamic Port range from Domain Controllers"
          from_port   = 49152
          to_port     = 65535
          protocol    = "UDP"
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
    jumpserver = {
      description = "Security group in from existing Azure jumpservers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        ssh_tcp_jumpserver = {
          description = "22: Allow ssh traffic from Azure Jumpservers"
          from_port   = 22
          to_port     = 22
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        rpc_tcp_jumpserver = {
          description = "135: TCP MS-RPC AD connect ingress from Azure Jumpservers"
          from_port   = 135
          to_port     = 135
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        rpc_udp_jumpserver = {
          description = "135: UDP MS-RPC AD connect ingress from Azure Jumpservers"
          from_port   = 135
          to_port     = 135
          protocol    = "UDP"
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
        rdp_tcp_jumpserver = {
          description = "3389: TCP RDP ingress from Azure Jumpservers"
          from_port   = 3389
          to_port     = 3389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        rpc_udp_jumpserver = {
          description = "3389: UDP RDP ingress from Azure Jumpservers"
          from_port   = 3389
          to_port     = 3389
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
          description = "49152-65535: UDP Dynamic Port range from Azure Jumpservers"
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
    noms_core = {
      description = "Security group in from existing Azure noms_core"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        echo_noms_core_tcp = {
          description = "7: TCP echo requests from noms_core"
          from_port   = 7
          to_port     = 7
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.noms_core
        }
        echo_noms_core_udp = {
          description = "7: UDP echo requests from noms_core"
          from_port   = 7
          to_port     = 7
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.noms_core
        }
        ssh_noms_core = {
          description = "22: Allow ssh traffic from noms_core"
          from_port   = 22
          to_port     = 22
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.noms_core
        }
        weblogic_admin_noms_core = {
          description = "7001: Allow weblogic admin traffic from noms_core"
          from_port   = 7001
          to_port     = 7001
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.noms_core
        }
        oracle_bi_noms_core = {
          description = "9704: Allow Oracle BI traffic from noms_core"
          from_port   = 9704
          to_port     = 9704
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.noms_core
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
    oasys_db = {
      description = "Allow traffic in from Oasys db servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        oasys_db_winrm = {
          description = "5985-5986: TCP WinRM ingress from Oasys db servers"
          from_port   = 5985
          to_port     = 5986
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
        }
        oasys_boe_cms = {
          description = "6400: TCP BOE CMS ingress from Oasys db servers"
          from_port   = 6400
          to_port     = 6400
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
        }
        oasys-boe-sia-range = {
          description = "6410-6500: TCP BOE SIA range ingress from Oasys db servers"
          from_port   = 6410
          to_port     = 6500
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
        }
        oasys-weblogic-admin = {
          description = "7001: TCP Weblogic admin port ingress from Oasys db servers"
          from_port   = 7001
          to_port     = 7001
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
        }
        oasys-weblogic-oracle-bi = {
          description = "9704: TCP Oracle BI ingress from Oasys db servers"
          from_port   = 9704
          to_port     = 9704
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
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
  }
}
