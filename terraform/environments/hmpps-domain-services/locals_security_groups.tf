locals {

  security_group_cidrs_devtest = {
    azure_vnets = module.ip_addresses.azure_fixngo_cidrs.devtest
    domain_controllers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest_domain_controllers,
      module.ip_addresses.mp_cidrs.ad_fixngo_azure_domain_controllers,
    ])
    enduserclient_internal = [
      "10.0.0.0/8"
    ]
    enduserclient_public1 = flatten([
      module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
    ])
    enduserclient_public2 = flatten([
      module.ip_addresses.mp_cidrs.non_live_eu_west_nat,
    ])
    rd_session_hosts = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
  }
  security_group_cidrs_preprod_prod = {
    azure_vnets = module.ip_addresses.azure_fixngo_cidrs.prod
    domain_controllers = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod_domain_controllers,
      module.ip_addresses.mp_cidrs.ad_fixngo_hmpp_domain_controllers,
    ])
    enduserclient_internal = [
      "10.0.0.0/8"
    ]
    enduserclient_public1 = flatten([
      module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
    ])
    enduserclient_public2 = flatten([
      module.ip_addresses.mp_cidrs.live_eu_west_nat,
    ])
    rd_session_hosts = flatten([
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

    rd-session-host = {
      description = "Security group for RD Session Hosts"
      ingress = {
        rpc-from-rds = {
          description     = "Allow RPC from remote desktop connection broker"
          from_port       = 135
          to_port         = 135
          protocol        = "TCP"
          security_groups = ["rds"]
        }
        smb-from-rds = {
          description     = "Allow SMB from remote desktop connection broker"
          from_port       = 445
          to_port         = 445
          protocol        = "TCP"
          security_groups = ["rds"]
        }
        winrm-from-rds = {
          description     = "Allow WinRM from remote desktop connection broker"
          from_port       = 5985
          to_port         = 5986
          protocol        = "TCP"
          security_groups = ["rds"]
        }
        rpc-dynamic-from-rds = {
          description     = "Allow RPC dynamic ports from remote desktop connection broker"
          from_port       = 49152
          to_port         = 65535
          protocol        = "TCP"
          security_groups = ["rds"]
        }
      }
    }
    rdgw = {
      description = "Security group for Remote Desktop Gateways"
      ingress = {
        http-from-lb = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          security_groups = [
            "public-lb", "public-lb-2"
          ]
        }
        https-from-lb = {
          description = "Allow https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          security_groups = [
            "public-lb", "public-lb-2"
          ]
        }
      }
    }

    rds = {
      description = "Security group for Remote Desktop Services (ConnectionBroker and RDWeb)"
      ingress = {
        http-from-lb = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          security_groups = [
            "public-lb", "public-lb-2"
          ]
        }
        rpc-from-rdsessionhosts = {
          description = "Allow RPC from remote desktop session hosts"
          from_port   = 135
          to_port     = 135
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        https-from-lb = {
          description = "Allow https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          security_groups = [
            "public-lb", "public-lb-2"
          ]
        }
        rpc-dynamic-from-rdsessionhost = {
          description = "Allow RPC dynamic ports from remote desktop session hosts"
          from_port   = 49152
          to_port     = 65535
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
      }
    }

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
            "public-lb", "public-lb-2"
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
        rpc-session-host = {
          description = "Allow connection to RD Session Host"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        rpd-session-host = {
          description = "Allow connection to RD Session Host"
          from_port   = 3389
          to_port     = 3389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        rdp-session-host-udp = {
          description = "Allow connection to RD Session Host and internal RD Resources"
          from_port   = 3389
          to_port     = 3389
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        rdp-udp = {
          description = "RDP over UDP from external RD Clients to the Gateway"
          from_port   = 3391
          to_port     = 3391
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        winrm_rds = {
          description = "5985/6: Allow WinRM TCP ingress (powershell remoting) for RDS"
          from_port   = 5985
          to_port     = 5986
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        rpc_dynamic_tcp_rd_sessionhost = {
          description = "49152-65535: TCP Dynamic Port ingress from remote desktop session hosts"
          from_port   = 49152
          to_port     = 65535
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        rpc_dynamic_tcp_udp_sessionhost = {
          description = "49152-65535: TCP Dynamic Port ingress from remote desktop session hosts"
          from_port   = 49152
          to_port     = 65535
          protocol    = "UDP"
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

    private-jumpserver = {
      description = "Security group for jumpservers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        rpc_tcp_rds = {
          description = "135: Allow RPC TCP ingress from RDS"
          from_port   = 135
          to_port     = 135
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        rds_udp_rds = {
          description = "135: Allow RPC UDP ingress from RDS"
          from_port   = 135
          to_port     = 135
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        rpc_tcp_rds_cb = {
          description = "445: Allow RPC TCP ingress from Connection Broker"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        rdp_tcp_web = {
          description = "3389: Allow RDP TCP ingress"
          from_port   = 3389
          to_port     = 3389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        rdp_udp_web = {
          description = "3389: Allow RDP UDP ingress"
          from_port   = 3389
          to_port     = 3389
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        winrm_rds = {
          description = "5985/6: Allow WinRM TCP ingress (powershell remoting) for RDS"
          from_port   = 5985
          to_port     = 5986
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        dynamic_rpc_tcp_rds = {
          description = "49152-65535: Allow Dynamic RPC TCP ingress from RDS"
          from_port   = 49152
          to_port     = 65535
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
        dynamic_rpc_udp_rds = {
          description = "49152-65535: Allow Dyanmic RPC UDP ingress from RDS"
          from_port   = 49152
          to_port     = 65535
          protocol    = "UDP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
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
          cidr_blocks = local.security_group_cidrs.enduserclient_public1
        }
        https_lb = {
          description = "Allow enduserclient https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_public1
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
    public-lb-2 = {
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
          cidr_blocks = local.security_group_cidrs.enduserclient_public2
        }
        https_lb = {
          description = "Allow enduserclient https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_public2
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
