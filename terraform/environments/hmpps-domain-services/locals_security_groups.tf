locals {

  security_group_cidrs_devtest = {
    core = module.ip_addresses.azure_fixngo_cidrs.devtest_core
    ssh  = module.ip_addresses.azure_fixngo_cidrs.devtest
    enduserclient = [
      "10.0.0.0/8"
    ]
    # NOTE: REMOVE THIS WHEN MOVE TO NEW SG's
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.devtest,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
    ])
    rdp = {
      inbound = ["10.40.165.0/26", "10.112.3.0/26", "10.102.0.0/16"]
    }
    domain_controllers = module.ip_addresses.azure_fixngo_cidrs.devtest_domain_controllers
    jumpservers        = module.ip_addresses.azure_fixngo_cidrs.devtest_jumpservers
  }

  security_group_cidrs_preprod_prod = {
    core = module.ip_addresses.azure_fixngo_cidrs.prod_core
    ssh = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod_jumpservers,
      # AllowProdStudioHostingSshInBound from 10.244.0.0/22 not included
      module.ip_addresses.azure_fixngo_cidrs.prod_core,
      module.ip_addresses.azure_fixngo_cidrs.prod, # NOTE: may need removing at some point
    ])
    enduserclient = [
      "10.0.0.0/8"
    ]
    # NOTE: REMOVE THIS WHEN MOVE TO NEW SG's
    http7xxx = flatten([
      module.ip_addresses.azure_fixngo_cidrs.prod,
      module.ip_addresses.azure_fixngo_cidrs.internet_egress,
    ])
    rdp = {
      inbound = flatten([
        module.ip_addresses.azure_fixngo_cidrs.prod,
      ])
    }
    domain_controllers = module.ip_addresses.azure_fixngo_cidrs.prod_domain_controllers
    jumpservers        = module.ip_addresses.azure_fixngo_cidrs.prod_jumpservers
  }
  security_group_cidrs_by_environment = {
    development   = local.security_group_cidrs_devtest
    test          = local.security_group_cidrs_devtest
    preproduction = local.security_group_cidrs_preprod_prod
    production    = local.security_group_cidrs_preprod_prod
  }
  security_group_cidrs = local.security_group_cidrs_by_environment[local.environment]

  security_groups = {
    private_dc = {
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

    ############ NEWLY DEFINED SGs ############

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
        # IMPORTANT: check if an 'allow all from azure' rule is required, rather than subsequent load-balancer rules
        /* all-from-fixngo = {
          description = "Allow all ingress from fixngo"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          cidr_blocks = local.security_group_cidrs.enduserclient
        } */
        http_lb = {
          description = "Allow http ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
        }
        https_lb = {
          description = "Allow enduserclient https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.enduserclient
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
