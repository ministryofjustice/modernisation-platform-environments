locals {
  security_group_cidrs_devtest = {
    core = module.ip_addresses.azure_fixngo_cidrs.devtest_core
    ssh  = module.ip_addresses.azure_fixngo_cidrs.devtest
    enduserclient = [
      "10.0.0.0/8"
    ]
    rdp = {
      inbound = ["10.40.165.0/26", "10.112.3.0/26", "10.102.0.0/16"]
    }
    rdgateway = [module.ip_addresses.mp_cidr.development_test]
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      module.ip_addresses.azure_fixngo_cidrs.devtest_core,
    ])
    domain_controllers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest_domain_controllers,
      module.ip_addresses.mp_cidrs.ad_fixngo_azure_domain_controllers,
    ])
    jumpservers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest_jumpservers,
      # module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
  }

  security_group_cidrs_preprod_prod = {
    core = module.ip_addresses.azure_fixngo_cidrs.prod_core
    ssh = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod_jumpservers,
      # AllowProdStudioHostingSshInBound from 10.244.0.0/22 not included
      module.ip_addresses.azure_fixngo_cidrs.prod_core,
      module.ip_addresses.azure_fixngo_cidrs.prod, # NOTE: may need removing at some point
    ])
    enduserclient = [
      "10.0.0.0/8"
    ]
    rdp = {
      inbound = flatten([
        module.ip_addresses.azure_fixngo_cidrs.prod,
      ])
    }
    rdgateway = [module.ip_addresses.mp_cidr.preproduction_production]
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      module.ip_addresses.azure_fixngo_cidrs.prod_core,
    ])
    domain_controllers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod_domain_controllers,
      # module.ip_addresses.mp_cidrs.ad_fixngo_hmpp_domain_controllers, # hits rule limit, remove azure DCs first
    ])
    jumpservers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod_jumpservers,
      # module.ip_addresses.mp_cidr[module.environment.vpc_name],
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

    load-balancer = {
      description = "New security group for load-balancer"
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
        http7770_7771_lb = {
          description = "Allow http 7770-7771 ingress"
          from_port   = 7770
          to_port     = 7771
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        http7780_7781_lb = {
          description = "Allow http 7780-7781 ingress"
          from_port   = 7780
          to_port     = 7781
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
      description = "New security group for web-servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http_web = {
          description     = "80: http allow ingress"
          from_port       = 80
          to_port         = 80
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.enduserclient
          security_groups = ["load-balancer"]
        }
        rpc_tcp_web2 = {
          description     = "135: TCP MS-RPC allow ingress from app and db servers"
          from_port       = 135
          to_port         = 135
          protocol        = "TCP"
          security_groups = ["app", "database"]
        }
        netbios_web_tcp = {
          description = "137-139: TCP NetBIOS services"
          from_port   = 137
          to_port     = 139
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        netbios_web_udp = {
          description = "137-139: UDP NetBIOS services"
          from_port   = 137
          to_port     = 139
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        https_web = {
          description     = "443: enduserclient https ingress"
          from_port       = 443
          to_port         = 443
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.enduserclient
          security_groups = ["load-balancer"]
        }
        smb_tcp_web = {
          description = "445: TCP SMB allow ingress from 10.0.0.0/8"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        http7770_1_web = {
          description     = "Allow ingress from port 7770-7771"
          from_port       = 7770
          to_port         = 7771
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.enduserclient
          security_groups = ["load-balancer"]
        }
        http7780_1_web = {
          description     = "Allow ingress from port 7780-7781"
          from_port       = 7780
          to_port         = 7781
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.enduserclient
          security_groups = ["load-balancer"]
        }
        rpc_dynamic_tcp_web = {
          description     = "49152-65535: TCP Dynamic Port range"
          from_port       = 49152
          to_port         = 65535
          protocol        = "TCP"
          security_groups = ["app", "database"]
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

    app = {
      description = "New security group for application servers"
      ingress = {
        all-from-self = {
          description     = "Allow all ingress to self"
          from_port       = 0
          to_port         = 0
          protocol        = -1
          self            = true
          security_groups = ["web"]
        }
        rpc_tcp_app2 = {
          description     = "135: TCP MS-RPC allow ingress from app and db servers"
          from_port       = 135
          to_port         = 135
          protocol        = "TCP"
          security_groups = ["web", "database"]
        }
        smb_tcp_app = {
          description     = "445: TCP SMB allow ingress from app and db servers"
          from_port       = 445
          to_port         = 445
          protocol        = "TCP"
          security_groups = ["web", "database"]
        }
        http_2109_csr = {
          description = "2109: TCP CSR ingress"
          from_port   = 2109
          to_port     = 2109
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        http_45054_csr_app = {
          description = "45054: TCP CSR ingress"
          from_port   = 45054
          to_port     = 45054
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        rpc_dynamic_tcp_app = {
          description     = "49152-65535: TCP Dynamic Port range"
          from_port       = 49152
          to_port         = 65535
          protocol        = "TCP"
          security_groups = ["web", "database"]
          # NOTE: csr_clientaccess will need to be added here to cidr_blocks
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
      description = "New security group for database servers"
      ingress = {
        all-from-self = {
          description     = "Allow all ingress to self"
          from_port       = 0
          to_port         = 0
          protocol        = -1
          self            = true
          security_groups = ["web", "app"]
        }
        # IMPORTANT: check if an 'allow all from load-balancer' rule is required
        echo_core_tcp_db = {
          description = "7: Allow ingress from port 7 oem agent echo" # Not sure what this is
          from_port   = 7
          to_port     = 7
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_oem_agent
        }
        echo_core_udp_db = {
          description = "7: Allow ingress from port 7 oem agent echo" # Not sure what this is
          from_port   = 7
          to_port     = 7
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.oracle_oem_agent
        }
        ssh-db = {
          description = "22: SSH allow ingress"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.ssh
        }
        rpc_tcp_db = {
          description = "135: TCP MS-RPC AD connect ingress from Azure DC and Jumpserver"
          from_port   = 135
          to_port     = 135
          protocol    = "TCP"
          cidr_blocks = concat(local.security_group_cidrs.jumpservers, local.security_group_cidrs.domain_controllers)
        }
        rpc_udp_db = {
          description = "135: UDP MS-RPC AD connect ingress from Azure DC and Jumpserver"
          from_port   = 135
          to_port     = 135
          protocol    = "UDP"
          cidr_blocks = concat(local.security_group_cidrs.jumpservers, local.security_group_cidrs.domain_controllers)
        }
        oracle_1521_db = {
          description     = "Allow oracle database 1521 ingress"
          from_port       = "1521"
          to_port         = "1521"
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.oracle_db
          security_groups = ["web", "app"]
        }
        oracleoem_3872_db = {
          description = "Allow oem agent ingress"
          from_port   = "3872"
          to_port     = "3872"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_oem_agent
        }
        rpc_dynamic_tcp_db = {
          description = "49152-65535: TCP Dynamic Port range"
          from_port   = 49152
          to_port     = 65535
          protocol    = "TCP"
          cidr_blocks = concat(local.security_group_cidrs.jumpservers, local.security_group_cidrs.domain_controllers)
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

    fsx_windows = {
      description = "Security group for fsx windows"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        netbios_fsx = {
          description = "139: NetBIOS Session Service"
          from_port   = 139
          to_port     = 139
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        smb_fsx = {
          description = "445: Directory Services SMB file sharing"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        winrm_fsx = {
          description = "5985-5986: WinRM 2.0 (Microsoft Windows Remote Management)"
          from_port   = 5985
          to_port     = 5986
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

    remote-management = {
      description = "Security group for managing windows servers remotely"
      ingress = {
        rpc-from-jumpservers = {
          description = "135: TCP MS-RPC AD connect ingress from jumpservers"
          from_port   = 135
          to_port     = 135
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        smb-from-jumpserver = {
          description = "445: TCP SMB ingress from jumpservers"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        rdp-from-jumpservers = {
          description = "3389: Allow RDP ingress from jumpservers"
          from_port   = 3389
          to_port     = 3389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        winrm-from-jumpservers = {
          description = "5985-6: Allow WinRM ingress from jumpservers"
          from_port   = 5985
          to_port     = 5986
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        rpc-dynamic_from-jumpservers = {
          description = "49152-65535: TCP Dynamic Port range from jumpservers"
          from_port   = 49152
          to_port     = 65535
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
      }
      egress = {
        all-to-jumpservers = {
          description = "Allow all egress to jumpservers"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
      }
    }

  }
}



