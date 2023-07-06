locals {

  security_group_cidrs_devtest = {
    icmp = flatten([
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc
    ])
    ssh = module.ip_addresses.azure_fixngo_cidrs.devtest
    https_internal = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
      module.ip_addresses.azure_studio_hosting_cidrs.devtest,
      module.ip_addresses.azure_nomisapi_cidrs.devtest,
    ])
    https_external = flatten([
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
      "3.9.247.172/32", "18.168.31.162/32", "18.133.111.138/32", # public load balancer
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
    https_internal = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.moj_cidr.aws_cloud_platform_vpc,
      module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
      module.ip_addresses.azure_studio_hosting_cidrs.prod,
      module.ip_addresses.azure_nomisapi_cidrs.prod,
    ])
    https_external = flatten([
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
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
        http = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          # security_groups = [
          #   "private-jumpserver",
          #   "bastion-linux",
          # ]
          cidr_blocks = flatten([
            local.security_group_cidrs.https_internal
          ])
        }
        http8080 = {
          description = "Allow http8080 ingress"
          from_port   = 8080
          to_port     = 8080
          protocol    = "tcp"
          # no security groups on an NLB so need to put public and private on the internal ALB
          cidr_blocks = flatten([
            "0.0.0.0/0",
            local.security_group_cidrs.https_internal,
          ])
          #security_groups = ["private", "private_lb"]
        }
        https = {
          description = "Allow HTTPS ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          # no security groups on an NLB so need to put public and private on the internal ALB
          cidr_blocks = flatten([
            local.security_group_cidrs.https_internal,
            "0.0.0.0/0",
          ])
          #security_groups = ["private", "private_lb"]
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
    private_lb = { # add public lb to security group lists
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
          # no security groups on an NLB so need to put public and private on the internal ALB
          cidr_blocks = flatten([
            local.security_group_cidrs.https_internal,
          ])
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
    private_lb_internal = {
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
          cidr_blocks = flatten([
            local.security_group_cidrs.https_internal,
          ])
        }
        http8080 = {
          description = "Allow http8080 ingress"
          from_port   = 0
          to_port     = 8080
          protocol    = "tcp"
          # no security groups on an NLB so need to put public and private on the internal ALB
          cidr_blocks = flatten([
            local.security_group_cidrs.https_internal,
          ])
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
    private_lb_external = {
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
          cidr_blocks = flatten([
            local.security_group_cidrs.https_external,
          ])
        }
        http8080 = {
          description = "Allow http8080 ingress"
          from_port   = 0
          to_port     = 8080
          protocol    = "tcp"
          # no security groups on an NLB so need to put public and private on the internal ALB
          cidr_blocks = flatten([
            local.security_group_cidrs.https_external,
          ])
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
        http = {
          description     = "Allow http ingress"
          from_port       = 80
          to_port         = 80
          protocol        = "tcp"
          security_groups = ["private_lb"]
          cidr_blocks = flatten([
            local.security_group_cidrs.https_internal,
          ])
        }
        http8080 = {
          description = "Allow http8080 ingress"
          from_port   = 0
          to_port     = 8080
          protocol    = "tcp"
          # no security groups on an NLB so need to put public and private on the internal ALB
          cidr_blocks = flatten([
            local.security_group_cidrs.https_internal,
          ])
          security_groups = ["private_lb"]
        }
        https = {
          description = "Allow HTTPS ingress"
          from_port   = 0
          to_port     = 443
          protocol    = "tcp"
          # no security groups on an NLB so need to put public and private on the internal ALB
          cidr_blocks = flatten([
            local.security_group_cidrs.https_internal,
          ])
          security_groups = ["private_lb"]
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
        # ssh = {
        #   description = "Allow ssh ingress"
        #   from_port   = "22"
        #   to_port     = "22"
        #   protocol    = "TCP"
        #   cidr_blocks = local.security_group_cidrs.ssh
        #   security_groups = [
        #     # "bastion-linux",
        #   ]
        # }
        oracle1521 = {
          description = "Allow oracle database 1521 ingress"
          from_port   = "1521"
          to_port     = "1521"
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.oracle_db
          security_groups = [
            "private_lb_internal",
            # "private-jumpserver",
            # "private-web",
            # "bastion-linux",
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
