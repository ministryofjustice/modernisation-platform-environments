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
      inbound = ["10.40.165.0/26","10.112.3.0/26","10.102.3.0/26"]
    }
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
  }
  security_group_cidrs_by_environment = {
    development   = local.security_group_cidrs_devtest
    test = local.security_group_cidrs_devtest
    preproduction = local.security_group_cidrs_preprod_prod
    production = local.security_group_cidrs_preprod_prod
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
        # http135 = {
        #   description = "Allow ingress from port 135"
        #   from_port       = 135
        #   to_port         = 135
        #   protocol        = "Any"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http139 = {
        #   description = "Allow ingress from port 139"
        #   from_port       = 139
        #   to_port         = 139
        #   protocol        = "Any"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        https = {
          description = "Allow ingress from port 443"
          from_port       = 443
          to_port         = 443
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }

         http = {
          description = "Allow ingress from port 80"
          from_port       = 80
          to_port         = 80
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        # http445 = {
        #   description = "Allow ingress from port 445"
        #   from_port       = 445
        #   to_port         = 445
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        rdp = {
          description = "Allow ingress from port 3389"
          from_port       = 3389
          to_port         = 3389
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.rdp.inbound
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
        http = {
          description = "Allow ingress from port 80"
          from_port       = 80
          to_port         = 80
          protocol        = "TCP"
          cidr_blocks     = ["10.0.0.0/8"]
          security_groups = []
        }
        ssh = {
          description = "Allow SSH ingress"
          from_port = 22
          to_port = 22
          protocol = "tcp"
          cidr_blocks = local.security_group_cidrs.ssh
          security_groups = []
        }
        rdp = {
          description = "Allow ingress from port 3389"
          from_port       = 3389
          to_port         = 3389
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.rdp.inbound
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
        # http49152_65535 = {
        #   description = "Allow ingress from port 49152-65535"
        #   from_port       = 49152-65535
        #   to_port         = 49152-65535
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
        # http445 = {
        #   description = "Allow ingress from port 445"
        #   from_port       = 445
        #   to_port         = 445
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
          description = "Allow SSH ingress"
          from_port = 22
          to_port = 22
          protocol = "tcp"
          cidr_blocks = local.security_group_cidrs.ssh
          security_groups = []
        }
        # http49152_65535 = {
        #   description = "Allow ingress from port 49152-65535"
        #   from_port       = 49152-65535
        #   to_port         = 49152-65535
        #   protocol        = "TCP"
        #   cidr_blocks     = ["10.0.0.0/8"]
        #   security_groups = []
        # }
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

