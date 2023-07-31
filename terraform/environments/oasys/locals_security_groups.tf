locals {

  security_group_cidrs_devtest = {
    icmp = flatten([
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc
    ])
    ssh = module.ip_addresses.azure_fixngo_cidrs.devtest
    https_internal = flatten([
      "10.0.0.0/8",
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc, # "172.20.0.0/16"
    ])
    https_external = flatten([
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc, # "172.20.0.0/16"
      module.ip_addresses.external_cidrs.cloud_platform
    ])
    oracle_db = flatten([
      "10.0.0.0/8",
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc, # "172.20.0.0/16"
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      "${module.ip_addresses.mp_cidr[module.environment.vpc_name]}",
    ])
  }
  security_group_cidrs_preprod_prod = {
    icmp = flatten([
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc
    ])
    ssh = module.ip_addresses.azure_fixngo_cidrs.prod
    https_internal = flatten([
      "10.0.0.0/8",
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
    ])
    https_external = flatten([
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc, # "172.20.0.0/16"
    ])
    oracle_db = flatten([
      "10.0.0.0/8",
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
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

  baseline_security_groups = {
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
    private_lb = {
      description = "Security group for internal load balancer"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http8080 = {
          description = "Allow http8080 ingress"
          from_port   = 0
          to_port     = 8080
          protocol    = "tcp"
          cidr_blocks = flatten([
            local.security_group_cidrs.https_internal,
          ])
          security_groups = []
        }
        https = {
          description = "Allow https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = flatten([
            local.security_group_cidrs.https_internal,
          ])
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
    public_lb = {
      description = "Security group for internal load balancer"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http8080 = {
          description = "Allow http8080 ingress"
          from_port   = 0
          to_port     = 8080
          protocol    = "tcp"
          cidr_blocks = flatten([
            local.security_group_cidrs.https_external,
          ])
          security_groups = []
        }
        https = {
          description = "Allow https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = flatten([
            local.security_group_cidrs.https_external,
          ])
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
    private_web = {
      description = "Security group for web servers"
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
          cidr_blocks = distinct(flatten([
            local.security_group_cidrs.https_internal,
            local.security_group_cidrs.https_external,
          ]))
          security_groups = ["private_lb","public_lb"]
        }
        http8080 = {
          description = "Allow http8080 ingress"
          from_port   = 0
          to_port     = 8080
          protocol    = "tcp"
          cidr_blocks = distinct(flatten([
            local.security_group_cidrs.https_internal,
            local.security_group_cidrs.https_external,
          ]))
          security_groups = ["private_lb","public_lb"]
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
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        icmp = {
          description = "Allow icmp ingress"
          from_port   = -1
          to_port     = -1
          protocol    = "icmp"
          cidr_blocks = local.security_group_cidrs.icmp
        }
        ssh = {
          description = "Allow ssh ingress"
          from_port   = "22"
          to_port     = "22"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.ssh
          security_groups = [
            # "bastion-linux",
          ]
        }
        http8080 = {
          description = "Allow http 8080 ingress"
          from_port   = 8080
          to_port     = 8080
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.oracle_db
          security_groups = [
            "private_lb",
            # "private-jumpserver",
            # "private-web",
            # "bastion-linux",
          ]
        }
        oracle1521 = {
          description = "Allow oracle database 1521 ingress"
          from_port   = "1521"
          to_port     = "1521"
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.oracle_db
          security_groups = [
            "private_lb",
            # "private-jumpserver",
            # "private-web",
            # "bastion-linux",
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

  }
}
