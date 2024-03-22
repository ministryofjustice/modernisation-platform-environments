locals {
  security_group_cidrs_devtest = {
    domain_controllers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest_domain_controllers,
      module.ip_addresses.mp_cidrs.ad_fixngo_azure_domain_controllers,
    ])
    jumpservers = module.ip_addresses.azure_fixngo_cidrs.devtest_jumpservers
  }

  security_group_cidrs_preprod_prod = {
    domain_controllers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod_domain_controllers,
      # module.ip_addresses.mp_cidrs.ad_fixngo_hmpp_domain_controllers, # hits rule limit, remove azure DCs first
    ])
    jumpservers = module.ip_addresses.azure_fixngo_cidrs.prod_jumpservers
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
    # web = {
    #    description = "Security group for web servers"
    #    ingress = {
    #     all-from-self = {
    #       description = "Allow all ingress to self"
    #       from_port   = 0
    #       to_port     = 0
    #       protocol    = -1
    #       self        = true
    #     }
    #     FIXME: THIS IS FOR EXAMPLE ONLY - NEEDS CHECKING
    #     http_web = {
    #       description     = "80: Allow HTTP ingress from LB"
    #       from_port       = 80
    #       to_port         = 80
    #       protocol        = "TCP"
    #       cidr_blocks     = ["10.40.129.64/26"] # noms mgmt live jumpservers
    #       security_groups = ["loadbalancer"] # <= very important part!
    #     }
    #     https_web = {
    #       description = "443: Allow HTTPS ingress from Azure"
    #       from_port   = 443
    #       to_port     = 443
    #       protocol    = "TCP"
    #       cidr_blocks = local.security_group_cidrs.enduserclient
    #     }
    #    }
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
    # TODO: PLACEHOLDER FOR BOE SERVER - NOT YET DEPLOYED/USED
    # boe = {
    #     description = "Security group for Windows App Servers"
    #     ingress = {
    #         all-from-self = {
    #             description     = "Allow all ingress to self"
    #             from_port       = 0
    #             to_port         = 0
    #             protocol        = -1
    #             self            = true
    #             security_groups = ["web"] 
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
  }
}
