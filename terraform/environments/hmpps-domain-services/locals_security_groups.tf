locals {

  security_group_cidrs_devtest = {
    azure_vnets = module.ip_addresses.azure_fixngo_cidrs.devtest
  }
  security_group_cidrs_preprod_prod = {
    azure_vnets = module.ip_addresses.azure_fixngo_cidrs.prod
  }
  security_group_cidrs_by_environment = {
    development   = local.security_group_cidrs_devtest
    test          = local.security_group_cidrs_devtest
    preproduction = local.security_group_cidrs_preprod_prod
    production    = local.security_group_cidrs_preprod_prod
  }
  security_group_cidrs = merge(local.security_group_cidrs_by_environment[local.environment], {
    enduserclient_internal = [
      "10.0.0.0/8"
    ]
    enduserclient_public = flatten([
      module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public
    ])
  })

  security_groups = {
    rds-ec2s = {
      description = "Security group for Remote Desktop Service EC2s"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http-from-lb = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          security_groups = [
            "private-lb",
            "public-lb",
          ]
        }
        http-from-euc = {
          description = "Allow direct http access for testing"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_internal
        }
        https-from-euc = {
          description = "Allow direct https access for testing"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_internal
        }
        all-from-azure-vnets-vnet = {
          description = "Allow all from azure vnets"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = local.security_group_cidrs.azure_vnets
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

    public-lb = {
      description = "Security group for public load-balancer"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http_lb = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_public
        }
        https_lb = {
          description = "Allow enduserclient https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_public
        }
      }
      egress = {
        all = {
          description = "Allow all traffic outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }

    private-lb = {
      description = "Security group for internal load-balancer"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http_lb = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_internal
        }
        https_lb = {
          description = "Allow enduserclient https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_internal
        }
      }
      egress = {
        all = {
          description = "Allow all traffic outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }

    private-dc = {
      description = "Security group for Domain Controllers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http_lb = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          security_groups = [
            "load-balancer",
          ]
        }
        all-from-noms-test-vnet = {
          description = "Allow all from noms test vnet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.101.0.0/16"]
        }
        all-from-noms-mgmt-vnet = {
          description = "Allow all from noms mgmt vnet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.102.0.0/16"]
        }
        all-from-noms-test-dr-vnet = {
          description = "Allow all from noms test vnet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.111.0.0/16"]
        }
        all-from-noms-mgmt-dr-vnet = {
          description = "Allow all from noms mgmt dr vnet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.112.0.0/16"]
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


    load-balancer = {
      description = "New security group for load-balancer"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        http_lb = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_internal
        }
        https_lb = {
          description = "Allow enduserclient https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_internal
        }
      }
      egress = {
        all = {
          description = "Allow all traffic outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }
}
