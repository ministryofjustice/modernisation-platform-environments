locals {
  security_group_cidrs_devtest = {
    ssh = module.ip_addresses.azure_fixngo_cidrs.devtest
    https = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
    ])
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
    ])
    rdp = {
      inbound = ["10.40.165.0/26", "10.112.3.0/26", "10.102.3.0/26", "10.102.1.64/26", "10.102.0.128/26"]
    }
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.azure_studio_hosting_cidrs.devtest,
      module.ip_addresses.azure_nomisapi_cidrs.devtest,
      "${module.ip_addresses.mp_cidr[module.environment.vpc_name]}",
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      "${module.ip_addresses.mp_cidr[module.environment.vpc_name]}",
    ])
  }

  security_group_cidrs_preprod_prod = {
    ssh = module.ip_addresses.azure_fixngo_cidrs.devtest
    https = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
    ])
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
    ])
    rdp = {
      inbound = ["10.40.165.0/26"]
    }
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.azure_studio_hosting_cidrs.prod,
      module.ip_addresses.azure_nomisapi_cidrs.prod,
      "${module.ip_addresses.mp_cidr[module.environment.vpc_name]}",
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      "${module.ip_addresses.mp_cidr[module.environment.vpc_name]}",
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
          security_groups = [
          ]
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

        dns = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 53
          to_port         = 53
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        http = {
          description     = "Allow ingress from port 80"
          from_port       = 80
          to_port         = 80
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        rpc = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 135
          to_port         = 135
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        netbios = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 137
          to_port         = 139
          protocol        = -1
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        ldap = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 389
          to_port         = 389
          protocol        = -1
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        https = {
          description     = "Allow ingress from port 443"
          from_port       = 443
          to_port         = 443
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        smb = {
          description = "Allow ingress Azure domain controllers"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          # cidr_blocks     = var.modules.ip_addresses.azure_fixngo_ips.devtest.domain_controllers
          # cidr_blocks     = ["10.102.0.196/32"]
          security_groups = []
        }
        ldap_ssl = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 636
          to_port         = 636
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        global_catalog_3268_3269 = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 3268
          to_port         = 3269
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        rdp = {
          description     = "Allow ingress from port 3389"
          from_port       = 3389
          to_port         = 3389
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.rdp.inbound
          security_groups = []
        }
        active_directory_web_services = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 9389
          to_port         = 9389
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        rpc_dynamic = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 49152
          to_port         = 65535
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
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
          description     = "Allow SSH ingress"
          from_port       = 22
          to_port         = 22
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.ssh
          security_groups = []
        }
        dns = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 53
          to_port         = 53
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        # NOTE: this is a bit redundant as mod-platform does not allow http connections
        http = {
          description     = "Allow ingress from port 80"
          from_port       = 80
          to_port         = 80
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        rpc = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 135
          to_port         = 135
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        netbios = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 137
          to_port         = 139
          protocol        = -1
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        ldap = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 389
          to_port         = 389
          protocol        = -1
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        https = {
          description     = "Allow ingress from port 443"
          from_port       = 443
          to_port         = 443
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        smb = {
          description = "Allow ingress Azure domain controllers"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          # cidr_blocks     = var.modules.ip_addresses.azure_fixngo_ips.devtest.domain_controllers
          # cidr_blocks     = ["10.102.0.196/32"]
          security_groups = []
        }

        ldap_ssl = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 636
          to_port         = 636
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        global_catalog_3268_3269 = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 3268
          to_port         = 3269
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        rdp = {
          description     = "Allow ingress from port 3389"
          from_port       = 3389
          to_port         = 3389
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.rdp.inbound
          security_groups = []
        }
        active_directory_web_services = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 9389
          to_port         = 9389
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        rpc_dynamic = {
          description     = "Allow ingress Azure domain controllers"
          from_port       = 49152
          to_port         = 65535
          protocol        = "TCP"
          cidr_blocks     = [for ip in module.ip_addresses.azure_fixngo_ips.devtest.domain_controllers : "${ip}/32"]
          security_groups = []
        }
        # http2109 = {
        #   description = "Allow ingress from port 2109"
        #   from_port       = 2109
        #   to_port         = 2109
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = ["Web-SG-migration", "data-db"]
        # }
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
    DB-SG-migration = {
      description = "Security group for database servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        ssh = {
          description     = "Allow SSH ingress"
          from_port       = 22
          to_port         = 22
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.ssh
          security_groups = []
        }
        # http41521 = {
        #   description = "Allow ingress from port 1521"
        #   from_port       = 1521
        #   to_port         = 1521
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
        # http3872= {
        #   description = "Allow ingress from port 3872"
        #   from_port       = 3872
        #   to_port         = 3872
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
  }
}

