locals {

  security_group_cidrs_devtest = {
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
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
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
      egress = {
        all-to-rds = {
          description     = "Allow all egress to remote desktop connection broker"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          security_groups = ["rds"]
        }
      }
    }
    rdgw = {
      description = "Security group for Remote Desktop Gateways"
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
      egress = {
        all-rdp-to-rdsessionhosts = {
          description = "Allow RDP egress to all RD Session Hosts"
          from_port   = 3389
          to_port     = 3389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
      }
    }

    rds = {
      description = "Security group for Remote Desktop Services (ConnectionBroker and RDWeb)"
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
        rpc-dynamic-from-rdsessionhosts = {
          description = "Allow RPC dynamic ports from remote desktop session hosts"
          from_port   = 49152
          to_port     = 65535
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
        }
      }
      egress = {
        all-to-rdsessionhosts = {
          description = "Allow all egress to remote desktop session hosts"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = local.security_group_cidrs.rd_session_hosts
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
