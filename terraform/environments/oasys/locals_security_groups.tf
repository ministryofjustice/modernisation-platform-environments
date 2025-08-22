locals {

  security_group_cidrs_devtest = {
    icmp = flatten([
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc
    ])
    https_internal = flatten([
      "10.0.0.0/8",
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc, # "172.20.0.0/16"
    ])
    https_external_1 = flatten([
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
    ])
    https_external_2 = flatten([
      module.ip_addresses.external_cidrs.cloud_platform,
    ])
    https_external_monitoring = flatten([
      module.ip_addresses.mp_cidrs.non_live_eu_west_nat,
    ])
    oracle_db = flatten([
      "10.0.0.0/8",
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc, # "172.20.0.0/16"
      module.ip_addresses.moj_cidr.aws_data_engineering_dev,
    ])
    http7xxx = flatten([
      "10.0.0.0/8",
    ])
  }
  security_group_cidrs_preprod = {
    icmp = flatten([
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc
    ])
    https_internal = flatten([
      "10.0.0.0/8",
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc, # "172.20.0.0/16"
    ])
    https_external_1 = flatten([
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
      module.ip_addresses.external_cidrs.cloud_platform,
    ])
    https_external_2 = flatten([
      module.ip_addresses.external_cidrs.sodeco,
      module.ip_addresses.external_cidrs.interserve,
      module.ip_addresses.external_cidrs.meganexus,
      module.ip_addresses.external_cidrs.serco,
      module.ip_addresses.external_cidrs.rrp,
      module.ip_addresses.external_cidrs.eos,
      module.ip_addresses.external_cidrs.oasys_sscl,
      module.ip_addresses.external_cidrs.dtv,
      module.ip_addresses.external_cidrs.nps_wales,
      module.ip_addresses.external_cidrs.dxw,
    ])
    https_external_monitoring = flatten([
      module.ip_addresses.mp_cidrs.live_eu_west_nat,
    ])
    oracle_db = flatten([
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      "10.40.40.0/24", # pp oasys
      "10.40.37.0/24", # pp prison nomis
      module.ip_addresses.azure_fixngo_cidrs.prod_jumpservers,
      module.ip_addresses.moj_cidr.aws_data_engineering_stage,
    ])
    http7xxx = flatten([
      "10.0.0.0/8",
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
    ])
  }
  security_group_cidrs_prod = {
    icmp = flatten([
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc
    ])
    https_internal = flatten([
      "10.0.0.0/8",
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc, # "172.20.0.0/16"
    ])
    # too many rules to put in single SG so split over two
    https_external_1 = flatten([
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
      module.ip_addresses.external_cidrs.cloud_platform,
    ])
    https_external_2 = flatten([
      module.ip_addresses.external_cidrs.sodeco,
      module.ip_addresses.external_cidrs.interserve,
      module.ip_addresses.external_cidrs.meganexus,
      module.ip_addresses.external_cidrs.serco,
      module.ip_addresses.external_cidrs.rrp,
      module.ip_addresses.external_cidrs.eos,
      module.ip_addresses.external_cidrs.oasys_sscl,
      module.ip_addresses.external_cidrs.dtv,
      module.ip_addresses.external_cidrs.nps_wales,
      module.ip_addresses.external_cidrs.dxw,
    ])
    https_external_monitoring = flatten([
      module.ip_addresses.mp_cidrs.live_eu_west_nat,
    ])
    oracle_db = flatten([
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      "10.40.6.0/24", # prod oasys
      "10.40.3.0/24", # prod prison nomis
      module.ip_addresses.azure_fixngo_cidrs.prod_jumpservers,
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_data_engineering_prod,
    ])
    http7xxx = flatten([
      "10.0.0.0/8",
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
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
        https = {
          description = "Allow https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = flatten([
            local.security_group_cidrs.https_external_1,
            local.security_group_cidrs.https_external_monitoring,
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
    public_lb_2 = {
      description = "Security group for internal load balancer part 2"
      ingress = {
        all-from-self = {
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
          cidr_blocks = flatten([
            local.security_group_cidrs.https_external_2,
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
      ingress = merge(
        module.baseline_presets.security_groups["ec2-linux"].ingress,
        {
          all-from-self = {
            description = "Allow all ingress to self"
            from_port   = 0
            to_port     = 0
            protocol    = -1
            self        = true
          }
          http8080 = {
            description     = "Allow http8080 ingress"
            from_port       = 0
            to_port         = 8080
            protocol        = "tcp"
            cidr_blocks     = local.security_group_cidrs.https_internal
            security_groups = ["private_lb", "public_lb", "public_lb_2"]
          }
      })
      egress = merge(
        module.baseline_presets.security_groups["ec2-linux"].egress,
      )
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
        http8080 = {
          description = "Allow http 8080 ingress"
          from_port   = 8080
          to_port     = 8080
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.oracle_db
          security_groups = [
            "private_lb",
            "private_web",
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
            "bip",
            "private_web",
          ]
        }
      }
    }
    bip = {
      description = "Security group for bip"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http7001 = {
          description     = "Allow http7001 ingress"
          from_port       = 7001
          to_port         = 7001
          protocol        = "tcp"
          security_groups = []
          cidr_blocks     = local.security_group_cidrs.http7xxx
        }
        http9556 = {
          description     = "Allow http9556 ingress"
          from_port       = 9556
          to_port         = 9556
          protocol        = "tcp"
          security_groups = []
          cidr_blocks     = local.security_group_cidrs.http7xxx
        }
        http9704 = {
          description     = "Allow http9704 ingress"
          from_port       = 9704
          to_port         = 9704
          protocol        = "tcp"
          security_groups = ["data"]
          cidr_blocks     = local.security_group_cidrs.http7xxx
        }
      }
    }
  }
}
