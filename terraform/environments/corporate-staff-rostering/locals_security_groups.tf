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
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.azure_studio_hosting_cidrs.devtest,
      module.ip_addresses.azure_nomisapi_cidrs.devtest,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      module.ip_addresses.azure_fixngo_cidrs.devtest_core,
    ])
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
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.azure_studio_hosting_cidrs.prod,
      module.ip_addresses.azure_nomisapi_cidrs.prod,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      module.ip_addresses.azure_fixngo_cidrs.prod_core,
    ])
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
    data_db = {
      description = "Security group for database servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        oracle1521 = {
          description = "Allow oracle database 1521 ingress"
          from_port   = "1521"
          to_port     = "1521"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_db
          security_groups = ["migration-web-sg", "migration-app-sg"
          ]
        }
        ssh = {
          description     = "Allow SSH ingress"
          from_port       = 22
          to_port         = 22
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.ssh
          security_groups = []
        }
        oracle3872 = {
          description = "Allow oem agent ingress"
          from_port   = "3872"
          to_port     = "3872"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_oem_agent
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

    Web-SG-migration = {
      description = "Security group for web servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        # NOTE: this is a bit redundant as mod-platform does not allow http connections
        http = {
          description     = "80: http allow ingress"
          from_port       = 80
          to_port         = 80
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = ["migration-web-sg", "migration-app-sg"]
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
          cidr_blocks     = local.security_group_cidrs.rdp.inbound
          security_groups = []
        }
        http7770_1 = {
          description     = "Allow ingress from port 7770-7771"
          from_port       = 7770
          to_port         = 7771
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["migration-web-sg", "migration-app-sg"]
        }
        http7780_1 = {
          description     = "Allow ingress from port 7780-7781"
          from_port       = 7780
          to_port         = 7781
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["migration-web-sg", "migration-app-sg"]
        }
        # http5985 = {
        #   description = "Allow ingress from port 5985"
        #   from_port       = 5985
        #   to_port         = 5985
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http5986 = {
        #   description = "Allow ingress from port 5986"
        #   from_port       = 5986
        #   to_port         = 5986
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http9100 = {
        #   description = "Allow ingress from port 9100"
        #   from_port       = 9100
        #   to_port         = 9100
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http9172 = {
        #   description = "Allow ingress from port 9172"
        #   from_port       = 9172
        #   to_port         = 9172
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http9182 = {
        #   description = "Allow ingress from port 9182"
        #   from_port       = 9182
        #   to_port         = 9182
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http49152_65535 = {
        #   description = "Allow ingress from port 49152-65535"
        #   from_port       = 49152-65535
        #   to_port         = 49152-65535
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # } 
        # All commented Ingress rules will be added later after servers are deployed into T3
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

    App-SG-migration = {
      description = "security group for application servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        ssh = {
          description     = "22: SSH allow ingress"
          from_port       = 22
          to_port         = 22
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.ssh
          security_groups = []
        }

        # NOTE: this is a bit redundant as mod-platform does not allow http connections
        http = {
          description     = "80: http allow ingress"
          from_port       = 80
          to_port         = 80
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        https = {
          description     = "443: https ingress"
          from_port       = 443
          to_port         = 443
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        http_2109_csr = {
          description = "2109: TCP CSR ingress"
          from_port   = 2109
          to_port     = 2109
          protocol    = "TCP"
          cidr_blocks = ["10.0.0.0/8"]
        }
        rdp = {
          description     = "3389: Allow RDP ingress"
          from_port       = 3389
          to_port         = 3389
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.rdp.inbound
          security_groups = []
        }
        winrm = {
          description     = "5985-6: Allow WinRM ingress"
          from_port       = 5985
          to_port         = 5986
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"] # TODO: change this to Jumpserver IP range from Azure
          security_groups = []
        }
        http_45054_csr = {
          description     = "45054: TCP CSR ingress"
          from_port       = 45054
          to_port         = 45054
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }

        # http5985 = {
        #   description = "Allow ingress from port 5985"
        #   from_port       = 5985
        #   to_port         = 5985
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http5986 = {
        #   description = "Allow ingress from port 5986"
        #   from_port       = 5986
        #   to_port         = 5986
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http9100 = {
        #   description = "Allow ingress from port 9100"
        #   from_port       = 9100
        #   to_port         = 9100
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http9172 = {
        #   description = "Allow ingress from port 9172"
        #   from_port       = 9172
        #   to_port         = 9172
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http9182 = {
        #   description = "Allow ingress from port 9182"
        #   from_port       = 9182
        #   to_port         = 9182
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http45054 = {
        #   description = "Allow ingress from port 45054"
        #   from_port       = 45054
        #   to_port         = 45054
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http7001 = {
        #   description = "Allow ingress from port 7001"
        #   from_port       = 7001
        #   to_port         = 7001
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http7= {
        #   description = "Allow ingress from port 7"
        #   from_port       = 7
        #   to_port         = 7
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
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


    domain-controller-access = {
      description = "Security group for domain controller inbound"
      ingress = {
        /* dns = {
          description     = "53: Allow DNS ingress from Azure DC"
          from_port       = 53
          to_port         = 53
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        } */
        kerberos_tcp = {
          description     = "88: TCP Allow Kerberos ingress from Azure DC"
          from_port       = 88
          to_port         = 88
          protocol        = "TCP"
          cidr_blocks     = ["10.102.0.0/16"]
          security_groups = []
        }
        kerberos_udp = {
          description     = "88: UDP Allow Kerberos ingress from Azure DC"
          from_port       = 88
          to_port         = 88
          protocol        = "UDP"
          cidr_blocks     = ["10.102.0.0/16"]
          security_groups = []
        }
        kerberos_tcp_pwd = {
          description     = "464: TCP Allow Kerberos Password Change ingress from Azure DC"
          from_port       = 464
          to_port         = 464
          protocol        = "TCP"
          cidr_blocks     = ["10.102.0.0/16"]
          security_groups = []
        }
        kerberos_udp_pwd = {
          description     = "464: UDP Allow Kerberos Password Change ingress from Azure DC"
          from_port       = 464
          to_port         = 464
          protocol        = "UDP"
          cidr_blocks     = ["10.102.0.0/16"]
          security_groups = []
        }
        rpc_udp = {
          description     = "135: UDP MS-RPC AD connect ingress from Azure DC"
          from_port       = 135
          to_port         = 135
          protocol        = "UDP"
          cidr_blocks     = ["10.102.0.0/16"]
          security_groups = ["migration-web-sg", "migration-app-sg"]
        }
        rpc_tcp = {
          description     = "135: TCP MS-RPC AD connect ingress from Azure DC"
          from_port       = 135
          to_port         = 135
          protocol        = "TCP"
          cidr_blocks     = ["10.102.0.0/16"]
          security_groups = ["migration-web-sg", "migration-app-sg"]
        }
        netbios_tcp = {
          description     = "137-139: TCP NetBIOS ingress from Azure DC"
          from_port       = 137
          to_port         = 139
          protocol        = "TCP"
          cidr_blocks     = ["10.102.0.0/16"]
          security_groups = []
        }
        netbios_udp = {
          description     = "137-139: UDP NetBIOS ingress from Azure DC"
          from_port       = 137
          to_port         = 139
          protocol        = "UDP"
          cidr_blocks     = ["10.102.0.0/16"]
          security_groups = []
        }
        ldap_tcp = {
          description     = "389: TCP Allow LDAP ingress from Azure DC"
          from_port       = 389
          to_port         = 389
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        ldap_udp = {
          description     = "389: UDP Allow LDAP ingress from Azure DC"
          from_port       = 389
          to_port         = 389
          protocol        = "UDP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        smb_udp = {
          description = "445: UDP SMB ingress from Azure DC"
          from_port   = 445
          to_port     = 445
          protocol    = "UDP"
          cidr_blocks = ["10.102.0.0/16"]
          # cidr_blocks     = var.modules.ip_addresses.azure_fixngo_ips.devtest.domain_controllers
          # cidr_blocks     = ["10.102.0.196/32"]
          security_groups = ["migration-web-sg", "migration-app-sg"]
        }
        smb_tcp = {
          description = "445: TCP SMB ingress from Azure DC"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = ["10.102.0.0/16"]
          # cidr_blocks     = var.modules.ip_addresses.azure_fixngo_ips.devtest.domain_controllers
          # cidr_blocks     = ["
          security_groups = ["migration-web-sg", "migration-app-sg"]
        }
        ldap_ssl = {
          description     = "636: TCP LDAP SSL ingress from Azure DC"
          from_port       = 636
          to_port         = 636
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        ldap_ssl_udp = {
          description     = "636: UDP LDAP SSL ingress from Azure DC"
          from_port       = 636
          to_port         = 636
          protocol        = "UDP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        global_catalog_3268_3269 = {
          description     = "3268-3269: Allow LDAP connection to Global Catalog over plain text and SSL"
          from_port       = 3268
          to_port         = 3269
          protocol        = "TCP"
          cidr_blocks     = ["10.102.0.0/16"]
          security_groups = []
        }
        /* active_directory_web_services = {
          description     = "9389: Allow Active Directory Web Services ingress from Azure DC"
          from_port       = 9389
          to_port         = 9389
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        } */
        rpc_dynamic_udp = {
          description     = "49152-65535: UDP Dynamic Port range"
          from_port       = 49152
          to_port         = 65535
          protocol        = "UDP"
          cidr_blocks     = ["10.102.0.0/16"]
          security_groups = ["migration-web-sg", "migration-app-sg"]
        }
        rpc_dynamic_tcp = {
          description     = "49152-65535: TCP Dynamic Port range"
          from_port       = 49152
          to_port         = 65535
          protocol        = "TCP"
          cidr_blocks     = ["10.102.0.0/16"]
          security_groups = ["migration-web-sg", "migration-app-sg"]
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
        # IMPORTANT: check if an 'allow all from load-balancer' rule is required
        http_web = {
          description     = "80: http allow ingress"
          from_port       = 80
          to_port         = 80
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.enduserclient
          security_groups = ["load-balancer"]
          # NOTE: will need to be changed to point to client access possibly
        }
        rpc_tcp_web = {
          description     = "135: TCP MS-RPC allow ingress from app and db servers"
          from_port       = 135
          to_port         = 135
          protocol        = "TCP"
          security_groups = ["app", "database"]
          # NOTE: csr_clientaccess will need to be added here to cidr_blocks
        }
        rpc_tcp_web = {
          description     = "135: UDP MS-RPC allow ingress from app and db servers"
          from_port       = 135
          to_port         = 135
          protocol        = "UDP"
          security_groups = ["app", "database"]
          # NOTE: csr_clientaccess will need to be added here to cidr_blocks
        }
        https_web = {
          description     = "443: enduserclient https ingress"
          from_port       = 443
          to_port         = 443
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.enduserclient
          security_groups = ["load-balancer"]
          # IMPORTANT: this doesn't seem to be part of the existing Azure SG's? NEEDS CHECKING
        }
        smb_tcp_web = {
          description     = "445: TCP SMB allow ingress from app and db servers"
          from_port       = 445
          to_port         = 445
          protocol        = "TCP"
          security_groups = ["app", "database"]
          # NOTE: csr_clientaccess will need to be added here to cidr_blocks
        }
        smb_udp_web = {
          description     = "445: UDP SMB allow ingress from app and db servers"
          from_port       = 445
          to_port         = 445
          protocol        = "UDP"
          security_groups = ["app", "database"]
          # NOTE: csr_clientaccess will need to be added here to cidr_blocks
        }
        rdp_tcp_web = {
          description = "3389: Allow RDP ingress"
          from_port   = 3389
          to_port     = 3389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
          # NOTE: AllowRDPPortForwardingInbound not applied from azurefirewallsubnet = "10.40.165.0/26" on TCP 3389
        }
        rdp_udp_web = {
          description = "3389: Allow RDP ingress"
          from_port   = 3389
          to_port     = 3389
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        winrm_web = {
          description = "5985-6: Allow WinRM ingress"
          from_port   = 5985
          to_port     = 5986
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        http7770_1_web = {
          description     = "Allow ingress from port 7770-7771"
          from_port       = 7770
          to_port         = 7771
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.enduserclient
          security_groups = ["load-balancer"]
          # NOTE: will need to be changed to include client access but load-balancer access allowed in
        }
        http7780_1_web = {
          description     = "Allow ingress from port 7780-7781"
          from_port       = 7780
          to_port         = 7781
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.enduserclient
          security_groups = ["load-balancer"]
          # NOTE: will need to be changed to include client access but load-balancer access allowed in
        }
        rpc_dynamic_udp_web = {
          description     = "49152-65535: UDP Dynamic Port range"
          from_port       = 49152
          to_port         = 65535
          protocol        = "UDP"
          security_groups = ["app", "database"]
          # NOTE: csr_clientaccess will need to be added here to cidr_blocks
        }
        rpc_dynamic_tcp_web = {
          description     = "49152-65535: TCP Dynamic Port range"
          from_port       = 49152
          to_port         = 65535
          protocol        = "TCP"
          security_groups = ["app", "database"]
          # NOTE: csr_clientaccess will need to be added here to cidr_blocks
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
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        # IMPORTANT: check if an 'allow all from load-balancer' rule is required
        # IMPORTANT: check whether http/https traffic is still needed? It's in the original but not used at an app level
        rpc_tcp_app = {
          description     = "135: TCP MS-RPC allow ingress from app and db servers"
          from_port       = 135
          to_port         = 135
          protocol        = "TCP"
          security_groups = ["app", "database"]
          # NOTE: csr_clientaccess will need to be added here to cidr_blocks
        }
        rpc_tcp_app = {
          description     = "135: UDP MS-RPC allow ingress from app and db servers"
          from_port       = 135
          to_port         = 135
          protocol        = "UDP"
          security_groups = ["app", "database"]
          # NOTE: csr_clientaccess will need to be added here to cidr_blocks
        }
        smb_tcp_app = {
          description     = "445: TCP SMB allow ingress from app and db servers"
          from_port       = 445
          to_port         = 445
          protocol        = "TCP"
          security_groups = ["app", "database"]
          # NOTE: csr_clientaccess will need to be added here to cidr_blocks
        }
        smb_udp_app = {
          description     = "445: UDP SMB allow ingress from app and db servers"
          from_port       = 445
          to_port         = 445
          protocol        = "UDP"
          security_groups = ["app", "database"]
          # NOTE: csr_clientaccess will need to be added here to cidr_blocks
        }
        http_2109_csr = {
          description = "2109: TCP CSR ingress"
          from_port   = 2109
          to_port     = 2109
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
          # IMPORTANT: check if this needs to be changed to include client access
        }
        rdp_tcp_app = {
          description = "3389: Allow RDP ingress"
          from_port   = 3389
          to_port     = 3389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        rdp_udp_app = {
          description = "3389: Allow RDP ingress"
          from_port   = 3389
          to_port     = 3389
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        winrm_app = {
          description = "5985-6: Allow WinRM ingress"
          from_port   = 5985
          to_port     = 5986
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.jumpservers
        }
        http_45054_csr_app = {
          description = "45054: TCP CSR ingress"
          from_port   = 45054
          to_port     = 45054
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
          # IMPORTANT: check if this needs to be changed to include client access
        }
        rpc_dynamic_udp_app = {
          description     = "49152-65535: UDP Dynamic Port range"
          from_port       = 49152
          to_port         = 65535
          protocol        = "UDP"
          security_groups = ["app", "database"]
          # NOTE: csr_clientaccess will need to be added here to cidr_blocks
        }
        rpc_dynamic_tcp_app = {
          description     = "49152-65535: TCP Dynamic Port range"
          from_port       = 49152
          to_port         = 65535
          protocol        = "TCP"
          security_groups = ["app", "database"]
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
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
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
  }
}



