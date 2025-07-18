locals {
  security_group_cidrs_devtest = {
    enduserclient = [
      "10.0.0.0/8"
    ]
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
  }

  security_group_cidrs_preprod_prod = {
    enduserclient = [
      "10.0.0.0/8"
    ]
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
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
      }
    }
    prisoner-retail = {
      description = "Security group for prisoner retail"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
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
        oracle_1521_db = {
          description     = "Allow oracle database 1521 ingress"
          from_port       = "1521"
          to_port         = "1521"
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.oracle_db
          security_groups = ["web", "app"]
        }
      }
    }
  }
}
