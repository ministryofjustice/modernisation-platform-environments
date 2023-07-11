locals {

  # NOTE: Following traffic also seen 
  # 10.0.0.0/11 (10.5.14.151/32 and 10.7.44.0/24 and 10.18.40.75/32)
  # 10.41.16.0/21
  # 10.148.0.0/14
  # 10.152.0.0/15
  # 10.171.0.0/16
  # 10.172.0.0/16
  # 10.208.0.0/12
  # 172.17.0.0/16 ??
  #
  # Mod Platform firewall is now allowing 10.0.0.0/8 for HTTPS for
  # production and preproduction accounts

  security_group_cidrs_devtest = {
    icmp = flatten([
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc
    ])
    ssh = module.ip_addresses.azure_fixngo_cidrs.devtest
    https = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
      module.ip_addresses.azure_studio_hosting_cidrs.devtest,
      module.ip_addresses.azure_nomisapi_cidrs.devtest,
    ])
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
    ])
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.azure_studio_hosting_cidrs.devtest,
      module.ip_addresses.azure_nomisapi_cidrs.devtest,
      module.ip_addresses.mp_cidr.hmpps-development,
      module.ip_addresses.mp_cidr.hmpps-test,
    ])
    oracle_oem_agent = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
    ])
  }
  security_group_cidrs_preprod_prod = {
    icmp = flatten([
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc
    ])
    ssh = module.ip_addresses.azure_fixngo_cidrs.prod
    https = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
      module.ip_addresses.azure_studio_hosting_cidrs.prod,
      module.ip_addresses.azure_nomisapi_cidrs.prod,
    ])
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
    ])
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.azure_studio_hosting_cidrs.prod,
      module.ip_addresses.azure_nomisapi_cidrs.prod,
    ])
    oracle_oem_agent = flatten([
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

  security_groups = {
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
        http = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          security_groups = [
            "private-jumpserver",
            "bastion-linux",
          ]
          cidr_blocks = local.security_group_cidrs.https
        }
        https = {
          description = "Allow https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          security_groups = [
            "private-jumpserver",
            "bastion-linux",
          ]
          cidr_blocks = local.security_group_cidrs.https
        }
        http7001 = {
          description = "Allow http7001 ingress"
          from_port   = 7001
          to_port     = 7001
          protocol    = "tcp"
          security_groups = [
            "private-jumpserver",
            "bastion-linux",
          ]
          cidr_blocks = local.security_group_cidrs.http7xxx
        }
        http7777 = {
          description = "Allow http7777 ingress"
          from_port   = 7777
          to_port     = 7777
          protocol    = "tcp"
          security_groups = [
            "private-jumpserver",
            "bastion-linux",
          ]
          cidr_blocks = local.security_group_cidrs.http7xxx
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
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        ssh = {
          description = "Allow ssh ingress"
          from_port   = "22"
          to_port     = "22"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.ssh
          security_groups = [
            "bastion-linux",
          ]
        }
        http7001 = {
          description = "Allow http7001 ingress"
          from_port   = 7001
          to_port     = 7001
          protocol    = "tcp"
          security_groups = [
            "private-jumpserver",
            "private-lb",
            "bastion-linux",
          ]
          cidr_blocks = local.security_group_cidrs.http7xxx
        },
        http7777 = {
          description = "Allow http7777 ingress"
          from_port   = 7777
          to_port     = 7777
          protocol    = "tcp"
          security_groups = [
            "private-jumpserver",
            "private-lb",
            "bastion-linux",
          ]
          cidr_blocks = local.security_group_cidrs.http7xxx
        },
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
    private_jumpserver = {
      description = "Security group for jumpservers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        rdp = {
          description = "Allow rdp ingress"
          from_port   = "3389"
          to_port     = "3389"
          protocol    = "TCP"
          security_groups = [
            "bastion-linux",
          ]
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

    data_db = {
      description = "Security group for databases"
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
            "bastion-linux",
          ]
        }
        oracle1521 = {
          description = "Allow oracle database 1521 ingress"
          from_port   = "1521"
          to_port     = "1521"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_db
          security_groups = [
            "private-jumpserver",
            "private-web",
            "bastion-linux",
          ]
        }
        oracle3872 = {
          description = "Allow oem agent ingress"
          from_port   = "3872"
          to_port     = "3872"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_oem_agent
          security_groups = [
            "private-jumpserver",
            "private-web",
            "bastion-linux",
          ]
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
