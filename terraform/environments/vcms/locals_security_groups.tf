locals {

  security_group_cidrs_devtest = {
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
  }
  security_group_cidrs_preprod = {
  }
  security_group_cidrs_prod = {
  }
  security_group_cidrs_by_environment = {
    development   = local.security_group_cidrs_devtest
    test          = local.security_group_cidrs_devtest
    preproduction = local.security_group_cidrs_preprod
    production    = local.security_group_cidrs_prod
  }
  security_group_cidrs = local.security_group_cidrs_by_environment[local.environment]

  security_groups = {
    # private_lb = {
    #   description = "Security group for internal load balancer"
    #   ingress = {
    #     all-from-self = {
    #       description = "Allow all ingress to self"
    #       from_port   = 0
    #       to_port     = 0
    #       protocol    = -1
    #       self        = true
    #     }
    #     https = {
    #       description = "Allow https ingress"
    #       from_port   = 443
    #       to_port     = 443
    #       protocol    = "tcp"
    #       cidr_blocks = flatten([
    #         local.security_group_cidrs.https_internal,
    #       ])
    #     }
    #   }
    #   egress = {
    #     all = {
    #       description     = "Allow all egress"
    #       from_port       = 0
    #       to_port         = 0
    #       protocol        = "-1"
    #       cidr_blocks     = ["0.0.0.0/0"]
    #       security_groups = []
    #     }
    #   }
    # }
    # public_lb = {
    #   description = "Security group for internal load balancer"
    #   ingress = {
    #     all-from-self = {
    #       description = "Allow all ingress to self"
    #       from_port   = 0
    #       to_port     = 0
    #       protocol    = -1
    #       self        = true
    #     }
    #     https = {
    #       description = "Allow https ingress"
    #       from_port   = 443
    #       to_port     = 443
    #       protocol    = "tcp"
    #       cidr_blocks = flatten([
    #         local.security_group_cidrs.https_external_1,
    #         local.security_group_cidrs.https_external_monitoring,
    #       ])
    #     }
    #   }
    #   egress = {
    #     all = {
    #       description     = "Allow all egress"
    #       from_port       = 0
    #       to_port         = 0
    #       protocol        = "-1"
    #       cidr_blocks     = ["0.0.0.0/0"]
    #       security_groups = []
    #     }
    #   }
    # }
    # public_lb_2 = {
    #   description = "Security group for internal load balancer part 2"
    #   ingress = {
    #     all-from-self = {
    #       description = "Allow all ingress to self"
    #       from_port   = 0
    #       to_port     = 0
    #       protocol    = -1
    #       self        = true
    #     }
    #     https = {
    #       description = "Allow https ingress"
    #       from_port   = 443
    #       to_port     = 443
    #       protocol    = "tcp"
    #       cidr_blocks = flatten([
    #         local.security_group_cidrs.https_external_2,
    #       ])
    #     }
    #   }
    #   egress = {
    #     all = {
    #       description     = "Allow all egress"
    #       from_port       = 0
    #       to_port         = 0
    #       protocol        = "-1"
    #       cidr_blocks     = ["0.0.0.0/0"]
    #       security_groups = []
    #     }
    #   }
    # }
  }
}
