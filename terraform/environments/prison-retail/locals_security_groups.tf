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
    development   = local.security_group_cidrs_devtest
    test          = local.security_group_cidrs_devtest
    preproduction = local.security_group_cidrs_preprod_prod
    production    = local.security_group_cidrs_preprod_prod
  }
  security_group_cidrs = local.security_group_cidrs_by_environment[local.environment]

  security_groups = {
    prison-retail = {
      description = "Security group for prisoner retail"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        TCP_3389 = {
          description = "Allow RDP ingress 3389"
          from_port   = 3389
          to_port     = 3389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        TCP_445 = {
          description = "Allow SMB ingress 445"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
      }
    }
  }
}
