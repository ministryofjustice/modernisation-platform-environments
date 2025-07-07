locals {

  security_group_cidrs_devtest = {
    icmp = flatten([
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc
    ])
    https = flatten([
      "10.0.0.0/8", # too many end-user addresses to list
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
    ])
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
  }
  security_group_cidrs_preprod_prod = {
    icmp = flatten([
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc
    ])
    https = flatten([
      "10.0.0.0/8", # too many end-user addresses to list
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
    ])
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    oracle_db = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidr.aws_analytical_platform_aggregate,
      module.ip_addresses.moj_cidr.aws_xsiam_prod_vpc,
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
    private-lb = {
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
          cidr_blocks = local.security_group_cidrs.https
        }
        https = {
          description = "Allow https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.https
        }
        http7001 = {
          description = "Allow http7001 ingress"
          from_port   = 7001
          to_port     = 7001
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.http7xxx
        }
        http7777 = {
          description = "Allow http7777 ingress"
          from_port   = 7777
          to_port     = 7777
          protocol    = "tcp"
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

    # ideally would attach ec2-linux to EC2 as well but they are in an
    # ASG, so just merge the rules instead
    private-web = {
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
          http7001 = {
            description = "Allow http7001 ingress"
            from_port   = 7001
            to_port     = 7001
            protocol    = "tcp"
            security_groups = [
              "private-lb",
            ]
            cidr_blocks = local.security_group_cidrs.http7xxx
          }
          http7777 = {
            description = "Allow http7777 ingress"
            from_port   = 7777
            to_port     = 7777
            protocol    = "tcp"
            security_groups = [
              "private-lb",
            ]
            cidr_blocks = local.security_group_cidrs.http7xxx
          }
        }
      )
      egress = merge(
        module.baseline_presets.security_groups["ec2-linux"].egress,
      )
    }

    # ideally would attach ec2-linux to EC2 as well but they are in an
    # ASG, so just merge the rules instead
    private-jumpserver = {
      description = "Security group for jumpservers"
      ingress = merge(
        module.baseline_presets.security_groups["ec2-windows"].ingress,
        module.baseline_presets.security_groups["ad-join"].ingress,
        {
          all-from-self = {
            description = "Allow all ingress to self"
            from_port   = 0
            to_port     = 0
            protocol    = -1
            self        = true
          }
        }
      )
      egress = merge(
        module.baseline_presets.security_groups["ec2-windows"].egress,
        module.baseline_presets.security_groups["ad-join"].egress,
      )
    }

    data-db = {
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
        oracle1521 = {
          description = "Allow oracle database 1521 ingress"
          from_port   = "1521"
          to_port     = "1521"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_db
          security_groups = [
            "private-web",
          ]
        }
      }
    }
  }
}
