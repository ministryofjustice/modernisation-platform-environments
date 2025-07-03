locals {

  security_group_cidrs_devtest = {
    enduserclient = [
      "10.0.0.0/8"
    ]
    http80 = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest_jumpservers,
      module.ip_addresses.mp_cidr[module.environment.vpc_name]
    ])
  }

  security_group_cidrs_preprod_prod = {
    enduserclient = [
      "10.0.0.0/8"
    ]
    http80 = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod_jumpservers,
      module.ip_addresses.mp_cidr[module.environment.vpc_name]
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
        http_web = {
          description     = "80: Allow HTTP ingress from LB"
          from_port       = 80
          to_port         = 80
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.http80
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
        all-from-self = {
          description     = "Allow all ingress to self"
          from_port       = 0
          to_port         = 0
          protocol        = -1
          self            = true
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
    database = {
      description = "Security group for WINDOWS SQL database servers"
      ingress = {
        all-from-self = {
          description     = "Allow all ingress to self"
          from_port       = 0
          to_port         = 0
          protocol        = -1
          self            = true
          security_groups = ["web", "app"]
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
