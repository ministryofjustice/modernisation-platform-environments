locals {

  security_group_cidrs_devtest = {
    ssh = module.ip_addresses.azure_fixngo_cidrs.devtest
    https = flatten([
      "10.0.0.0/8",
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
    ])
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
    ])
  }

  security_group_cidrs_preprod_prod = {
    ssh = module.ip_addresses.azure_fixngo_cidrs.prod
    https = flatten([
      "10.0.0.0/8",
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
    ])
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
    ])
  }

  security_group_cidrs_by_environment = {
    development   = local.security_group_cidrs_devtest
    test          = local.security_group_cidrs_devtest
    preproduction = local.security_group_cidrs_preprod_prod
    production    = local.security_group_cidrs_preprod_prod
  }
  security_group_cidrs = local.security_group_cidrs_by_environment[local.environment]

  baseline_security_groups = {
    lb = {
      description = "Security group for public subnet"
      ingress = {
        all-within-subnet = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.https
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
          security_groups = []
        }
      }
    }
    web = {
      description = "Security group for tomcat web servers"
      ingress = {
        all-within-subnet = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http7010 = {
          description     = "Allow http7010 ingress"
          from_port       = 7010
          to_port         = 7010
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb"]
        }
        http7777 = {
          description     = "Allow http7777 ingress"
          from_port       = 7777
          to_port         = 7777
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb"]
        }
        http8005 = {
          description     = "Allow http8005 ingress"
          from_port       = 8005
          to_port         = 8005
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb"]
        }
        http8443 = {
          description     = "Allow http8443 ingress"
          from_port       = 8443
          to_port         = 8443
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb"]
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
    bip = {
      description = "Security group for bip"
      ingress = {
        all-from-web = {
          description = "Allow all ingress from web"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          security_groups ["web"]
        }
        all-within-subnet = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        host-agent = {
          description     = "Allow http1128 ingress"
          from_port       = 1128
          to_port         = 1128
          protocol        = "tcp"
          security_groups = ["web"]
        }
        subversion = {
          description     = "Allow http3690 ingress"
          from_port       = 3690
          to_port         = 3690
          protocol        = "tcp"
          security_groups = ["web"]
        }
        cms = {
          description     = "Allow http6400 ingress"
          from_port       = 6400
          to_port         = 6400
          protocol        = "tcp"
          security_groups = ["web"]
        }
        sia = {
          description     = "Allow http6410 to http6415 ingress"
          from_port       = 6410
          to_port         = 6415
          protocol        = "tcp"
          security_groups = ["web"]
        }
        adaptive-processing = {
          description     = "Allow adaptive processing ingress"
          from_port       = 6430
          to_port         = 6441
          protocol        = "tcp"
          security_groups = ["web"]
        }
        web-application-container = {
          description     = "Allow web application container ingress"
          from_port       = 6450
          to_port         = 6450
          protocol        = "tcp"
          security_groups = ["web"]
        }
        web-processing = {
          description     = "Allow web processing ingress"
          from_port       = 6460
          to_port         = 6470
          protocol        = "tcp"
          security_groups = ["web"]
        }
        wacs = {
          description     = "Allow http6455 ingress"
          from_port       = 6455
          to_port         = 6455
          protocol        = "tcp"
          security_groups = ["web"]
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
    etl = {
      description = "Security group for etl"
      ingress = {
        all-within-subnet = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        subversion = {
          description     = "Allow http3690 ingress"
          from_port       = 3690
          to_port         = 3690
          protocol        = "tcp"
          security_groups = []
        }
        http6450 = {
          description     = "Allow http6450 ingress"
          from_port       = 6450
          to_port         = 6450
          protocol        = "tcp"
          security_groups = []
        }
        http6455 = {
          description     = "Allow http6455 ingress"
          from_port       = 6455
          to_port         = 6455
          protocol        = "tcp"
          security_groups = []
        }
        http28080 = {
          description     = "Allow http28080 ingress"
          from_port       = 28080
          to_port         = 28080
          protocol        = "tcp"
          security_groups = []
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
          description = "Allow oracle database 1521 ingress"
          from_port   = "1521"
          to_port     = "1521"
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.oracle_db
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
  }
}
