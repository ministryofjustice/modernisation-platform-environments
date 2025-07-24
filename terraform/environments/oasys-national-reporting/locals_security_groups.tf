locals {
  security_group_cidrs_devtest = {
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    enduserclient_internal = flatten([
      "10.0.0.0/8",
    ])
    enduserclient_public1 = flatten([
      module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public
    ])
    enduserclient_public2 = flatten([
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.mp_cidrs.non_live_eu_west_nat,
    ])
    fsx_ingress = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    cms_ingress = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
  }

  security_group_cidrs_preprod_prod = {
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    enduserclient_internal = [
      "10.0.0.0/8"
    ]
    enduserclient_public1 = flatten([
      module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public
    ])
    enduserclient_public2 = flatten([
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
      module.ip_addresses.mp_cidrs.live_eu_west_nat,
    ])
    fsx_ingress = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    cms_ingress = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
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
        http = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_public1
        }
        https = {
          description = "Allow https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient_public1
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
    public-lb-2 = {
      description = "Security group for public load balancer part 2"
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
          cidr_blocks = local.security_group_cidrs.enduserclient_public2
        }
        https = {
          description = "Allow https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.enduserclient_public2
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
    efs = {
      description = "Security group for EFS"
      ingress = {
        nfs = {
          description     = "Allow nfs ingress"
          from_port       = 2049
          to_port         = 2049
          protocol        = "tcp"
          security_groups = ["bip-app", "bip-web"]
        }
      }
      egress = {
        all = {
          description     = "Allow all egress to bip and web"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          security_groups = ["bip-app", "bip-web"]
        }
      }
    }

    bip-web = {
      description = "Security group for bip web tier"
      ingress = {
        all-from-self = {
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
          security_groups = ["public-lb", "public-lb-2"]
        }
        http7777 = {
          description     = "Allow http7777 ingress"
          from_port       = 7777
          to_port         = 7777
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["public-lb", "public-lb-2"]
        }
        http8005 = {
          description     = "Allow http8005 ingress"
          from_port       = 8005
          to_port         = 8005
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["public-lb", "public-lb-2"]
        }
        http8443 = {
          description     = "Allow http8443 ingress"
          from_port       = 8443
          to_port         = 8443
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["public-lb", "public-lb-2"]
        }
      }
    }
    bip-app = {
      description = "Security group for bip application tier"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        all-from-web = {
          description     = "Allow all ingress from web"
          from_port       = 0
          to_port         = 0
          protocol        = -1
          security_groups = ["bip-web"]
        }
        cms-ingress = {
          description = "Allow http6400-http6500 ingress"
          from_port   = 6400
          to_port     = 6500
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.cms_ingress
        }
      }
    }

    bods = {
      # this is also the SG for FSX but we can't change description or FSX SG without recreating the resource
      description = "Security group for BODS servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        smb = {
          description = "Allow fsx smb ingress"
          from_port   = 445
          to_port     = 445
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.fsx_ingress
        }
        winrm = {
          description = "Allow fsx winrm ingress"
          from_port   = 5985
          to_port     = 5986
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.fsx_ingress
        }
        cms-ingress = {
          description = "Allow http6400-http6500 ingress"
          from_port   = 6400
          to_port     = 6500
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.cms_ingress
        }
        http_28080 = {
          description     = "28080: bods tomcat http"
          from_port       = 28080
          to_port         = 28080
          protocol        = "TCP"
          security_groups = ["public-lb", "public-lb-2"]
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
