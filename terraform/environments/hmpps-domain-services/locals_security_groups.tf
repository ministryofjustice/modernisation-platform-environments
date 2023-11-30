locals {

  security_group_cidrs_devtest = {
    core = module.ip_addresses.azure_fixngo_cidrs.devtest_core
    ssh  = module.ip_addresses.azure_fixngo_cidrs.devtest
    enduserclient = [
      "10.0.0.0/8"
    ]
    # NOTE: REMOVE THIS WHEN MOVE TO NEW SG's
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
    ])
    rdp = {
      inbound = ["10.40.165.0/26", "10.112.3.0/26", "10.102.0.0/16"]
    }
    domain_controllers = module.ip_addresses.azure_fixngo_cidrs.devtest_domain_controllers
    jumpservers        = module.ip_addresses.azure_fixngo_cidrs.devtest_jumpservers
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
    # NOTE: REMOVE THIS WHEN MOVE TO NEW SG's
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
    ])
    rdp = {
      inbound = flatten([
        module.ip_addresses.azure_fixngo_cidrs.prod,
      ])
    }
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
    private_dc = {
      description = "Security group for Domain Controllers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        all-from-noms-test-vnet = {
          description = "Allow all from noms test vnet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.101.0.0/16"]
        }
        all-from-noms-mgmt-vnet = {
          description = "Allow all from noms mgmt vnet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.102.0.0/16"]
        }
        all-from-noms-test-dr-vnet = {
          description = "Allow all from noms test vnet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.111.0.0/16"]
        }
        all-from-noms-mgmt-dr-vnet = {
          description = "Allow all from noms mgmt dr vnet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.112.0.0/16"]
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

    ############ NEWLY DEFINED SGs ############

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
        # IMPORTANT: check if an 'allow all from azure' rule is required, rather than subsequent load-balancer rules
        /* all-from-fixngo = {
          description = "Allow all ingress from fixngo"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          cidr_blocks = local.security_group_cidrs.enduserclient
        } */
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

    #web = {
    #  description = "New security group for web-servers"
    #  ingress = {
    #    all-from-self = {
    #      description = "Allow all ingress to self"
    #      from_port   = 0
    #      to_port     = 0
    #      protocol    = -1
    #      self        = true
    #    }
    #    # IMPORTANT: check if an 'allow all from load-balancer' rule is required
    #    http_web = {
    #      description     = "80: http allow ingress"
    #      from_port       = 80
    #      to_port         = 80
    #      protocol        = "TCP"
    #      cidr_blocks     = local.security_group_cidrs.enduserclient
    #      security_groups = ["load-balancer"]
    #      # NOTE: will need to be changed to point to client access possibly
    #    }
    #    rpc_tcp_web = {
    #      description     = "135: TCP MS-RPC allow ingress from app and db servers"
    #      from_port       = 135
    #      to_port         = 135
    #      protocol        = "TCP"
    #      security_groups = ["app", "database"]
    #      # NOTE: csr_clientaccess will need to be added here to cidr_blocks
    #    }
    #    rpc_tcp_web = {
    #      description     = "135: UDP MS-RPC allow ingress from app and db servers"
    #      from_port       = 135
    #      to_port         = 135
    #      protocol        = "UDP"
    #      security_groups = ["app", "database"]
    #      # NOTE: csr_clientaccess will need to be added here to cidr_blocks
    #    }
    #    https_web = {
    #      description     = "443: enduserclient https ingress"
    #      from_port       = 443
    #      to_port         = 443
    #      protocol        = "TCP"
    #      cidr_blocks     = local.security_group_cidrs.enduserclient
    #      security_groups = ["load-balancer"]
    #      # IMPORTANT: this doesn't seem to be part of the existing Azure SG's? NEEDS CHECKING
    #    }
    #    smb_tcp_web = {
    #      description     = "445: TCP SMB allow ingress from app and db servers"
    #      from_port       = 445
    #      to_port         = 445
    #      protocol        = "TCP"
    #      security_groups = ["app", "database"]
    #      # NOTE: csr_clientaccess will need to be added here to cidr_blocks
    #    }
    #    smb_udp_web = {
    #      description     = "445: UDP SMB allow ingress from app and db servers"
    #      from_port       = 445
    #      to_port         = 445
    #      protocol        = "UDP"
    #      security_groups = ["app", "database"]
    #      # NOTE: csr_clientaccess will need to be added here to cidr_blocks
    #    }
    #    rdp_tcp_web = {
    #      description = "3389: Allow RDP ingress"
    #      from_port   = 3389
    #      to_port     = 3389
    #      protocol    = "TCP"
    #      cidr_blocks = local.security_group_cidrs.jumpservers
    #      # NOTE: AllowRDPPortForwardingInbound not applied from azurefirewallsubnet = "10.40.165.0/26" on TCP 3389
    #    }
    #    rdp_udp_web = {
    #      description = "3389: Allow RDP ingress"
    #      from_port   = 3389
    #      to_port     = 3389
    #      protocol    = "UDP"
    #      cidr_blocks = local.security_group_cidrs.jumpservers
    #    }
    #    winrm_web = {
    #      description = "5985-6: Allow WinRM ingress"
    #      from_port   = 5985
    #      to_port     = 5986
    #      protocol    = "TCP"
    #      cidr_blocks = local.security_group_cidrs.jumpservers
    #    }
    #    http7770_1_web = {
    #      description     = "Allow ingress from port 7770-7771"
    #      from_port       = 7770
    #      to_port         = 7771
    #      protocol        = "TCP"
    #      cidr_blocks     = local.security_group_cidrs.enduserclient
    #      security_groups = ["load-balancer"]
    #      # NOTE: will need to be changed to include client access but load-balancer access allowed in
    #    }
    #    http7780_1_web = {
    #      description     = "Allow ingress from port 7780-7781"
    #      from_port       = 7780
    #      to_port         = 7781
    #      protocol        = "TCP"
    #      cidr_blocks     = local.security_group_cidrs.enduserclient
    #      security_groups = ["load-balancer"]
    #      # NOTE: will need to be changed to include client access but load-balancer access allowed in
    #    }
    #    rpc_dynamic_udp_web = {
    #      description     = "49152-65535: UDP Dynamic Port range"
    #      from_port       = 49152
    #      to_port         = 65535
    #      protocol        = "UDP"
    #      security_groups = ["app", "database"]
    #      # NOTE: csr_clientaccess will need to be added here to cidr_blocks
    #    }
    #    rpc_dynamic_tcp_web = {
    #      description     = "49152-65535: TCP Dynamic Port range"
    #      from_port       = 49152
    #      to_port         = 65535
    #      protocol        = "TCP"
    #      security_groups = ["app", "database"]
    #      # NOTE: csr_clientaccess will need to be added here to cidr_blocks
    #    }
    #  }
    #  egress = {
    #    all = {
    #      description     = "Allow all egress"
    #      from_port       = 0
    #      to_port         = 0
    #      protocol        = "-1"
    #      cidr_blocks     = ["0.0.0.0/0"]
    #      security_groups = []
    #    }
    #  }
    #}
    #app = {
    #  description = "New security group for application servers"
    #  ingress = {
    #    all-from-self = {
    #      description = "Allow all ingress to self"
    #      from_port   = 0
    #      to_port     = 0
    #      protocol    = -1
    #      self        = true
    #    }
    #    # IMPORTANT: check if an 'allow all from load-balancer' rule is required
    #    # IMPORTANT: check whether http/https traffic is still needed? It's in the original but not used at an app level
    #    rpc_tcp_app = {
    #      description     = "135: TCP MS-RPC allow ingress from app and db servers"
    #      from_port       = 135
    #      to_port         = 135
    #      protocol        = "TCP"
    #      security_groups = ["app", "database"]
    #      # NOTE: csr_clientaccess will need to be added here to cidr_blocks
    #    }
    #    rpc_tcp_app = {
    #      description     = "135: UDP MS-RPC allow ingress from app and db servers"
    #      from_port       = 135
    #      to_port         = 135
    #      protocol        = "UDP"
    #      security_groups = ["app", "database"]
    #      # NOTE: csr_clientaccess will need to be added here to cidr_blocks
    #    }
    #    smb_tcp_app = {
    #      description     = "445: TCP SMB allow ingress from app and db servers"
    #      from_port       = 445
    #      to_port         = 445
    #      protocol        = "TCP"
    #      security_groups = ["app", "database"]
    #      # NOTE: csr_clientaccess will need to be added here to cidr_blocks
    #    }
    #    smb_udp_app = {
    #      description     = "445: UDP SMB allow ingress from app and db servers"
    #      from_port       = 445
    #      to_port         = 445
    #      protocol        = "UDP"
    #      security_groups = ["app", "database"]
    #      # NOTE: csr_clientaccess will need to be added here to cidr_blocks
    #    }
    #    http_2109_csr = {
    #      description = "2109: TCP CSR ingress"
    #      from_port   = 2109
    #      to_port     = 2109
    #      protocol    = "TCP"
    #      cidr_blocks = local.security_group_cidrs.enduserclient
    #      # IMPORTANT: check if this needs to be changed to include client access
    #    }
    #    rdp_tcp_app = {
    #      description = "3389: Allow RDP ingress"
    #      from_port   = 3389
    #      to_port     = 3389
    #      protocol    = "TCP"
    #      cidr_blocks = local.security_group_cidrs.jumpservers
    #    }
    #    rdp_udp_app = {
    #      description = "3389: Allow RDP ingress"
    #      from_port   = 3389
    #      to_port     = 3389
    #      protocol    = "UDP"
    #      cidr_blocks = local.security_group_cidrs.jumpservers
    #    }
    #    winrm_app = {
    #      description = "5985-6: Allow WinRM ingress"
    #      from_port   = 5985
    #      to_port     = 5986
    #      protocol    = "TCP"
    #      cidr_blocks = local.security_group_cidrs.jumpservers
    #    }
    #    http_45054_csr_app = {
    #      description = "45054: TCP CSR ingress"
    #      from_port   = 45054
    #      to_port     = 45054
    #      protocol    = "TCP"
    #      cidr_blocks = local.security_group_cidrs.enduserclient
    #      # IMPORTANT: check if this needs to be changed to include client access
    #    }
    #    rpc_dynamic_udp_app = {
    #      description     = "49152-65535: UDP Dynamic Port range"
    #      from_port       = 49152
    #      to_port         = 65535
    #      protocol        = "UDP"
    #      security_groups = ["app", "database"]
    #      # NOTE: csr_clientaccess will need to be added here to cidr_blocks
    #    }
    #    rpc_dynamic_tcp_app = {
    #      description     = "49152-65535: TCP Dynamic Port range"
    #      from_port       = 49152
    #      to_port         = 65535
    #      protocol        = "TCP"
    #      security_groups = ["app", "database"]
    #      # NOTE: csr_clientaccess will need to be added here to cidr_blocks
    #    }
    #  }
    #  egress = {
    #    all = {
    #      description = "Allow all traffic outbound"
    #      from_port   = 0
    #      to_port     = 0
    #      protocol    = "-1"
    #      cidr_blocks = ["0.0.0.0/0"]
    #    }
    #  }
    #}
  }
}
