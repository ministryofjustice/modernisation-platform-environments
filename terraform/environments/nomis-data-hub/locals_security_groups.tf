locals {

  security_group_cidrs_devtest = {
    https = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
    ])
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
    ])
    http8555 = flatten([
      module.ip_addresses.mp_cidr.development_test
    ])
    tcp7222 = flatten([
      module.ip_addresses.mp_cidr.development_test
    ])
  }
  security_group_cidrs_preprod = {
    https = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
    ])
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
    ])
    http8555 = flatten([
      module.ip_addresses.mp_cidr.hmpps-preproduction
    ])
    tcp7222 = flatten([
      module.ip_addresses.mp_cidr.hmpps-preproduction
    ])
  }
  security_group_cidrs_prod = {
    https = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
    ])
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
    ])
    http8555 = flatten([
      module.ip_addresses.mp_cidr.hmpps-production
    ])
    tcp7222 = flatten([
      module.ip_addresses.mp_cidr.hmpps-production
    ])
  }

  security_group_cidrs_by_environment = {
    development   = local.security_group_cidrs_devtest
    test          = local.security_group_cidrs_devtest
    preproduction = local.security_group_cidrs_preprod
    production    = local.security_group_cidrs_prod
  }
  security_group_cidrs = local.security_group_cidrs_by_environment[local.environment]

  security_groups = {
    public = {
      description = "Security group for public subnet"
      ingress = {
        all-within-subnet = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        https = {
          description = "Allow https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.https
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
        }
      }
    }
    private = {
      description = "Security group for private subnet"
      ingress = {
        all-within-subnet = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http8080 = {
          description     = "Allow http8080 ingress"
          from_port       = 8080
          to_port         = 8080
          protocol        = "tcp"
          security_groups = ["public"]
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
        }
      }
    }
    management_server = {
      description = "Security group for management server"
      ingress = {
        all-within-subnet = {
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
        }
      }
    }
    ndh_app = {
      description = "Security group for ndh app"
      ingress = {
        all-within-subnet = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http8080 = {
          description     = "Allow http8080 ingress"
          from_port       = 8080
          to_port         = 8080
          protocol        = "tcp"
          security_groups = ["management_server"]
        }
        http8555 = { # from oasys
          description     = "Allow http8555 ingress"
          from_port       = 8555
          to_port         = 8555
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.http8555
        }
        tcp-ems = {
          description     = "Allow all ems ingress"
          from_port       = 0
          to_port         = 65535
          protocol        = "tcp"
          security_groups = ["ndh_ems"]
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
        }
      }
    }
    ndh_ems = {
      description = "Security group for ndh ems"
      ingress = {
        all-within-subnet = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http8080 = {
          description     = "Allow http8080 ingress"
          from_port       = 8080
          to_port         = 8080
          protocol        = "tcp"
          security_groups = ["management_server"]
        }
        tcp7222 = { # from nomis (XTAG)
          description     = "Allow port 7222 ingress"
          from_port       = 7222
          to_port         = 7222
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.tcp7222
        }
        tcp7224 = {
          description     = "Allow port 7224 ingress"
          from_port       = 7224
          to_port         = 7224
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.tcp7222
        }
        tcp-app = {
          description     = "Allow all app ingress"
          from_port       = 0
          to_port         = 65535
          protocol        = "tcp"
          security_groups = ["ndh_app"]
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
        }
      }
    }
    data = {
      description = "Security group for data subnet"
      ingress = {
        all-within-subnet = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        oracle1521 = {
          description     = "Allow oracle database 1521 ingress"
          from_port       = "1521"
          to_port         = "1521"
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.oracle_db
          security_groups = ["private"]
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
        }
      }
    }
  }
}
