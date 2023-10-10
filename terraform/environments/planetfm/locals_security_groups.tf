locals {

  security_group_cidrs_devtest = {
    core = module.ip_addresses.azure_fixngo_cidrs.devtest_core
    enduserclient = [
      "10.0.0.0/8"
    ]
    domain_controllers = module.ip_addresses.azure_fixngo_cidrs.devtest_domain_controllers
    jumpservers        = module.ip_addresses.azure_fixngo_cidrs.devtest_jumpservers
  }

  security_group_cidrs_preprod_prod = {
    core = module.ip_addresses.azure_fixngo_cidrs.prod_core
    enduserclient = [
      "10.0.0.0/8"
    ]
    domain_controllers = module.ip_addresses.azure_fixngo_cidrs.prod_domain_controllers
    jumpservers        = module.ip_addresses.azure_fixngo_cidrs.prod_jumpservers
  }

  security_group_cidrs_by_environment = {
    development   = local.security_group_cidrs_devtest
    test          = local.security_group_cidrs_devtest
    preproduction = local.security_group_cidrs_preprod_prod
    production    = local.security_group_cidrs_preprod_prod
  }

  security_group_cidrs = local.security_group_cidrs_by_environment[local.environment]

  security_groups = {
    migration_cutover = {
      description = "Security group for migrated instances"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        https = {
          description     = "443: https ingress"
          from_port       = 443
          to_port         = 443
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }

        rdp = {
          description     = "3389: Allow RDP ingress"
          from_port       = 3389
          to_port         = 3389
          protocol        = "TCP"
          cidr_blocks     = ["10.40.50.128/26", "10.40.50.64/26", "10.40.50.0/26"]
          security_groups = []
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
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        https_web = {
          description = "443: Allow HTTPS ingress from Azure"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        rdp_tcp_web = {
          description = "3389: Allow RDP UDP ingress from jumpserver"
          from_port   = 3389
          to_port     = 3389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        rdp_udp_web = {
          description = "3389: Allow RDP UDP ingress from jumpserver"
          from_port   = 3389
          to_port     = 3389
          protocol    = "UDP"
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
    app = {
      description = "Security group for Windows App Servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        rdp_tcp_app = {
          description = "3389: Allow RDP UDP ingress from jumpserver"
          from_port   = 3389
          to_port     = 3389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        rdp_udp_app = {
          description = "3389: Allow RDP UDP ingress from jumpserver"
          from_port   = 3389
          to_port     = 3389
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        web_access_cafm_5504 = {
          description     = "All web access inbound on 5504"
          from_port       = 5504
          to_port         = 5504
          protocol        = "TCP"
          security_groups = ["database", "loadbalancer"]
          cidr_blocks     = local.security_group_cidrs.enduserclient # NOTE: this may need to change at some point
        }
        cafm_licensing_7071 = {
          description = "All CAFM licensing inbound on 7071"
          from_port   = 7071
          to_port     = 7071
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient # NOTE: this may need to change at some point
        }
        cafm_licensing_7073 = {
          description = "All CAFM licensing inbound on 7073"
          from_port   = 7073
          to_port     = 7073
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient # NOTE: this may need to change at some point
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
      # FIXME: note - this is currently INCOMPLETE
      description = "Security group for WINDOWS SQL database servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
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
