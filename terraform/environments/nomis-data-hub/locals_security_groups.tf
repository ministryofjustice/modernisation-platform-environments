locals {

  security_group_cidrs = {
    http8555 = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
    tcp7222 = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
    ])
  }

  security_groups = {
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
        all-from-ems = {
          description     = "Allow all ingress from ems tier"
          from_port       = 0
          to_port         = 0
          protocol        = -1
          security_groups = ["ndh_ems"]
        }
        http8080 = {
          description     = "Allow http8080 ingress"
          from_port       = 8080
          to_port         = 8080
          protocol        = "tcp"
          security_groups = ["management_server"]
        }
        http8555 = { # from oasys
          description = "Allow http8555 ingress"
          from_port   = 8555
          to_port     = 8555
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.http8555
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
        all-from-app = {
          description     = "Allow all ingress from app tier"
          from_port       = 0
          to_port         = 0
          protocol        = -1
          security_groups = ["ndh_app"]
        }
        http8080 = {
          description     = "Allow http8080 ingress"
          from_port       = 8080
          to_port         = 8080
          protocol        = "tcp"
          security_groups = ["management_server"]
        }
        tcp7222 = { # from nomis (XTAG)
          description = "Allow port 7222 ingress"
          from_port   = 7222
          to_port     = 7222
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.tcp7222
        }
        tcp7224 = {
          description = "Allow port 7224 ingress"
          from_port   = 7224
          to_port     = 7224
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.tcp7222
        }
      }
    }
  }
}
