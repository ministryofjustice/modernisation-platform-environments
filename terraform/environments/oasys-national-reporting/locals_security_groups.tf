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
    noms_core = module.ip_addresses.azure_fixngo_cidrs.devtest_core
    oasys_db = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      module.ip_addresses.azure_fixngo_cidrs.devtest_oasys_db,
    ])
    rdp = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      module.ip_addresses.azure_fixngo_cidrs.devtest
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
    noms_core = module.ip_addresses.azure_fixngo_cidrs.prod_core
    oasys_db = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      module.ip_addresses.azure_fixngo_cidrs.prod_oasys_db,
    ])
    rdp = flatten([
      module.ip_addresses.mp_cidr[module.environment.vpc_name],
      module.ip_addresses.azure_fixngo_cidrs.prod
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
    lb = {
      description = "Security group for public subnet"
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
          security_groups = ["private-jumpserver"]
          cidr_blocks     = local.security_group_cidrs.enduserclient_internal
        }
        https = {
          description     = "Allow https ingress"
          from_port       = 443
          to_port         = 443
          protocol        = "tcp"
          security_groups = ["private-jumpserver"]
          cidr_blocks     = local.security_group_cidrs.enduserclient_internal
        }
      }
      egress = {
        all = {
          description = "Allow all egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    web = {
      description = "Security group for web servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }

        oracle_oem_web_3872 = {
          description     = "3872: oracle oem agent"
          from_port       = 3872
          to_port         = 3872
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb", "private-jumpserver"]
        }
        oracle_oem_web_4983 = {
          description     = "4983: oracle oem agent"
          from_port       = 4983
          to_port         = 4983
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb", "private-jumpserver"]
        }

        weblogic_node_manager_web = {
          description     = "5556: weblogic node manager"
          from_port       = 5556
          to_port         = 5556
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb", "private-jumpserver"]
        }
        http7010 = {
          description     = "Allow http7010 ingress"
          from_port       = 7010
          to_port         = 7010
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb", "public-lb", "public-lb-2"]
        }
        weblogic_admin = {
          description     = "7001: Weblogic admin port"
          from_port       = 7001
          to_port         = 7001
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb", "private-jumpserver"]
        }
        oracle_weblogic_admin = {
          description     = "7777: Main Weblogic admin"
          from_port       = 7777
          to_port         = 7777
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb", "private-jumpserver"]
        }
        http_web = {
          description     = "8080: Allow HTTP ingress"
          from_port       = 8080
          to_port         = 8080
          protocol        = "TCP"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb", "private-jumpserver"]
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

    bip-web = {
      description = "Security group for bip web tier"
      ingress = {
        all-within-subnet = {
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
          security_groups = ["lb", "public-lb", "public-lb-2"]
        }
        http7777 = {
          description     = "Allow http7777 ingress"
          from_port       = 7777
          to_port         = 7777
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb", "public-lb", "public-lb-2"]
        }
        http8005 = {
          description     = "Allow http8005 ingress"
          from_port       = 8005
          to_port         = 8005
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb", "public-lb", "public-lb-2"]
        }
        http8443 = {
          description     = "Allow http8443 ingress"
          from_port       = 8443
          to_port         = 8443
          protocol        = "tcp"
          cidr_blocks     = local.security_group_cidrs.http7xxx
          security_groups = ["lb", "public-lb", "public-lb-2"]
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
    bip-app = {
      description = "Security group for bip application tier"
      ingress = {
        all-within-subnet = {
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
          description     = "Allow http6400-http6500 ingress"
          from_port       = 6400
          to_port         = 6500
          protocol        = "tcp"
          security_groups = ["private-jumpserver"]
          cidr_blocks     = ["10.0.0.0/8"] # added for testing, remove later
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

    boe = {
      description = "Security group for Windows App Servers"
      ingress = {
        all-from-self = {
          description     = "Allow all ingress to self"
          from_port       = 0
          to_port         = 0
          protocol        = -1
          self            = true
          security_groups = ["web", "onr_db"]
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

    bods = {
      description = "Security group for BODS servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        rdp_3389_tcp = {
          description = "3389: rdp tcp"
          from_port   = 3389
          to_port     = 3389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rdp
        }
        http_6400 = {
          description     = "6400: boe cms"
          from_port       = 6400
          to_port         = 6400
          protocol        = "TCP"
          security_groups = ["private-jumpserver"]
        }
        http_6410_6500 = {
          description     = "6410-6500: boe sia"
          from_port       = 6410
          to_port         = 6500
          protocol        = "TCP"
          security_groups = ["private-jumpserver"]
        }
        http_28080 = {
          description     = "28080: bods tomcat http"
          from_port       = 28080
          to_port         = 28080
          protocol        = "TCP"
          security_groups = ["public-lb", "private-jumpserver"]
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
    onr_db = {
      description = "Security group for ONR DB server"
      ingress = {
        all-from-self = {
          description     = "Allow all ingress to self"
          from_port       = 0
          to_port         = 0
          protocol        = -1
          self            = true
          security_groups = ["boe", "bods"]
        }
        onr_db_oem_agent = {
          description = "3872: Oracle OEM agent"
          from_port   = 3872
          to_port     = 3872
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.noms_core
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
    oasys_db = {
      description = "Allow traffic in from Oasys db servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        oasys_db_winrm = {
          description = "5985-5986: TCP WinRM ingress from Oasys db servers"
          from_port   = 5985
          to_port     = 5986
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
        }
        oasys_boe_cms = {
          description = "6400: TCP BOE CMS ingress from Oasys db servers"
          from_port   = 6400
          to_port     = 6400
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
        }
        oasys-boe-sia-range = {
          description = "6410-6500: TCP BOE SIA range ingress from Oasys db servers"
          from_port   = 6410
          to_port     = 6500
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
        }
        oasys-weblogic-admin = {
          description = "7001: TCP Weblogic admin port ingress from Oasys db servers"
          from_port   = 7001
          to_port     = 7001
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
        }
        oasys-weblogic-oracle-bi = {
          description = "9704: TCP Oracle BI ingress from Oasys db servers"
          from_port   = 9704
          to_port     = 9704
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
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
    oasys_db_onr_db = {
      description = "Allow traffic from Oasys db servers to ONR DB server"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        oasys_db_onr_db_1521 = {
          description = "1521: TCP Oracle DB access ingress from Oasys db servers to ONR DB server"
          from_port   = 1521
          to_port     = 1521
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
        }
        oasys_db_onr_db_7443 = {
          description = "7443: TCP Oracle DB access ingress from Oasys db servers to ONR DB server"
          from_port   = 7443
          to_port     = 7443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
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
    private-jumpserver = {
      description = "Security group for jumpservers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
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
    win-bip = {
      description = "Security group for Temporary Windows BIP server"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        oasys_db_onr_db_1521 = {
          description = "1521: TCP Oracle DB access ingress from Oasys db servers to ONR DB server"
          from_port   = 1521
          to_port     = 1521
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
        }
        oasys_db_onr_db_7443 = {
          description = "7443: TCP Oracle DB access ingress from Oasys db servers to ONR DB server"
          from_port   = 7443
          to_port     = 7443
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oasys_db
        }
        rdp_3389_tcp = {
          description = "3389: rdp tcp"
          from_port   = 3389
          to_port     = 3389
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.rdp
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
