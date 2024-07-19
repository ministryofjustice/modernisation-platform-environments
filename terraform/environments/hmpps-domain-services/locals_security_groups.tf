locals {

  security_group_cidrs_devtest = {
    azure_vnets = module.ip_addresses.azure_fixngo_cidrs.devtest
    domain_controllers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest_domain_controllers,
      module.ip_addresses.mp_cidrs.ad_fixngo_azure_domain_controllers,
    ])
    rd_session_hosts = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      module.ip_addresses.azure_fixngo_cidrs.devtest,
    ])
  }
  security_group_cidrs_preprod_prod = {
    azure_vnets = module.ip_addresses.azure_fixngo_cidrs.prod
    domain_controllers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod_domain_controllers,
      module.ip_addresses.mp_cidrs.ad_fixngo_hmpp_domain_controllers,
    ])
    rd_session_hosts = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      module.ip_addresses.azure_fixngo_cidrs.prod,
    ])
  }
  security_group_cidrs_by_environment = {
    development   = local.security_group_cidrs_devtest
    test          = local.security_group_cidrs_devtest
    preproduction = local.security_group_cidrs_preprod_prod
    production    = local.security_group_cidrs_preprod_prod
  }
  security_group_cidrs = merge(local.security_group_cidrs_by_environment[local.environment], {
    enduserclient_internal = [
      "10.0.0.0/8"
    ]
    enduserclient_public = flatten([
      module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public
    ])
  })

  security_groups = {
    rds-ec2s = {
      description = "Security group for Remote Desktop Service EC2s"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http-from-lb = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          security_groups = [
            "public-lb",
          ]
        }
        http-from-euc = {
          description = "Allow direct http access for testing"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_internal
        }
        rpc_udp_rd_sessionhost = {
          description = "135: UDP MS-RPC ingress from remote desktop session hosts"
          from_port   = 135
          to_port     = 135
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        rpc_tcp_rd_sessionhost = {
          description = "135: TCP MS-RPC ingress from remote desktop session hosts"
          from_port   = 135
          to_port     = 135
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        https-from-euc = {
          description = "Allow direct https access for testing"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_internal
        }
        rpc_dynamic_tcp_rd_sessionhost = {
          description = "49152-65535: TCP Dynamic Port ingress from remote desktop session hosts"
          from_port   = 49152
          to_port     = 65535
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        all-from-azure-vnets-vnet = {
          description = "Allow all from azure vnets"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = local.security_group_cidrs.azure_vnets
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

    public-lb = {
      description = "Security group for public load-balancer"
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
          cidr_blocks = local.security_group_cidrs.enduserclient_public
        }
        https_lb = {
          description = "Allow enduserclient https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_public
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

    # TODO - delete
    domain = {
      description = "Security group for Azure domain(s) access from Azure DCs"
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
  }
}
