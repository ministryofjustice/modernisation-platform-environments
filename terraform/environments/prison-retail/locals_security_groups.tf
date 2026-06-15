locals {
  security_group_cidrs_devtest = {
    enduserclient = [
      "10.0.0.0/8"
    ]
  }

  security_group_cidrs_preprod_prod = {
    enduserclient = [
      "10.0.0.0/8"
    ]
  }
  security_group_cidrs_by_environment = {
    # development   = local.security_group_cidrs_devtest
    # test          = local.security_group_cidrs_devtest
    # preproduction = local.security_group_cidrs_preprod_prod
    production = local.security_group_cidrs_preprod_prod
  }
  security_group_cidrs = local.security_group_cidrs_by_environment[local.environment]

  security_groups = {
    prison-retail = {
      # application specific ports; standard windows ports are in ec2-windows SG
      description = "Security group for prisoner retail"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        ICMP = {
          description = "Allow ping for client host availability check and MTU calculation"
          from_port   = -1
          to_port     = -1
          protocol    = "icmp"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        TCP_80 = {
          description = "Allow HTTP ingress 80 for WebDav check"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        TCP_445 = {
          description = "Allow SMB ingress 445"
          from_port   = 445
          to_port     = 445
          protocol    = "tcp"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
      }
    }
  }
}
