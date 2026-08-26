locals {

  security_groups_filter = flatten([
    var.options.enable_hmpps_domain ? ["ad-join"] : [],
    var.options.enable_ec2_security_groups ? ["ec2-linux"] : [],
    var.options.enable_ec2_security_groups ? ["ec2-windows"] : [],
    var.options.enable_ec2_security_groups && var.options.enable_ec2_oracle_enterprise_managed_server ? ["oem-agent"] : [],
  ])

  ad_netbios_name = contains(["development", "test"], var.environment.environment) ? "azure" : "hmpp"

  security_groups = {

    ad-join = {
      description = "Security group for resources that need to join the ${local.ad_netbios_name} active directory domain"
      ingress = {
        icmp = {
          description = "Allow ICMP ingress"
          protocol    = "ICMP"
          from_port   = 8
          to_port     = 0
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        rpc_tcp = {
          description = "Allow RPC ingress"
          from_port   = 135
          to_port     = 135
          protocol    = "TCP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        rpc_tcp_dynamic2 = {
          description = "Allow RPC dynamic port range"
          from_port   = 49152
          to_port     = 65535
          protocol    = "TCP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
      }
      egress = {
        all-to-dc = {
          # Ideally, we'd lock down to specific ports but we exceed maximum number of rules for SG
          # Ports required:
          #  - ICMP
          #  - DNS         tcp/53 udp/53
          #  - Kerberos    tcp/88 udp/88
          #  - NTP         udp/123
          #  - RPC         tcp/135
          #  - Netbios     udp/137 udp/138 tcp/139
          #  - LDAP        tcp/389 udp/389
          #  - SMB         tcp/445
          #  - Kerberos    tcp/464 udp/464 (Password Change)
          #  - LDAPs       tcp/636
          #  - LDAP GC     tcp/3268 tcp/3269 (Global Catalog for Cross Domain)
          #  - ADWS        tcp/9389
          #  - RPD Dynamic tcp/49152 - tcp/65536
          description = "Allow all egress to DCs"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
      }
    }

    ec2-linux = {
      description = "Security group for linux EC2s"

      ingress = {
      }

      egress = {
        all = {
          # allow all since internal resources are protected by inbound SGs
          # and outbound internet is protected by firewall
          description = "Allow all egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }

    ec2-windows = {
      description = "Security group for windows EC2s"

      ingress = merge(
        var.options.enable_hmpps_domain ? {
          rpc-from-jumpservers = {
            description = "Allow RPC from jumpservers"
            from_port   = 135
            to_port     = 135
            protocol    = "TCP"
            cidr_blocks = flatten([
              var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].jumpservers,
              var.ip_addresses.mp_cidr[var.environment.vpc_name],
            ])
          }
          smb-from-jumpserver = {
            description = "Allow SMB from jumpservers"
            from_port   = 445
            to_port     = 445
            protocol    = "TCP"
            cidr_blocks = flatten([
              var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].jumpservers,
              var.ip_addresses.mp_cidr[var.environment.vpc_name],
            ])
          }
          rdp-tcp-from-jumpservers = {
            description = "Allow RDP TCP from jumpservers"
            from_port   = 3389
            to_port     = 3389
            protocol    = "TCP"
            cidr_blocks = flatten([
              var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].rdgateways,
              var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].jumpservers,
              var.ip_addresses.mp_cidr[var.environment.vpc_name],
            ])
          }
          rdp-udp-from-jumpservers = {
            description = "Allow RDP UDP from jumpservers"
            from_port   = 3389
            to_port     = 3389
            protocol    = "UDP"
            cidr_blocks = flatten([
              var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].rdgateways,
              var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].jumpservers,
              var.ip_addresses.mp_cidr[var.environment.vpc_name],
            ])
          }
          winrm-from-jumpservers = {
            description = "Allow WinRM from jumpservers"
            from_port   = 5985
            to_port     = 5986
            protocol    = "TCP"
            cidr_blocks = flatten([
              var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].jumpservers,
              var.ip_addresses.mp_cidr[var.environment.vpc_name],
            ])
          }
          rpc-dynamic_from-jumpservers = {
            description = "Allow RPC dynamic from jumpservers"
            from_port   = 49152
            to_port     = 65535
            protocol    = "TCP"
            cidr_blocks = flatten([
              var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].jumpservers,
              var.ip_addresses.mp_cidr[var.environment.vpc_name],
            ])
          }
        } : {}
      )
      egress = {
        all = {
          # allow all since internal resources are protected by inbound SGs
          # and outbound internet is protected by firewall
          description = "Allow all egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }

    oem-agent = {
      description = "Security group for EC2s with Oracle OEM agent"

      ingress = {
        icmp = {
          description = "Allow ICMP ingress from OEM"
          protocol    = "ICMP"
          from_port   = 8
          to_port     = 0
          cidr_blocks = [var.ip_addresses.mp_cidr[var.environment.vpc_name]],
        }
        echo = {
          description = "Allow echo from OEM"
          protocol    = "TCP"
          from_port   = 7
          to_port     = 7
          cidr_blocks = [var.ip_addresses.mp_cidr[var.environment.vpc_name]],
        }
        ssh = {
          description = "Allow SSH from OEM"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = [var.ip_addresses.mp_cidr[var.environment.vpc_name]],
        }
        oracle-db-1521 = {
          description = "Allow oracle database 1521 ingress from OEM"
          from_port   = "1521"
          to_port     = "1521"
          protocol    = "TCP"
          cidr_blocks = [var.ip_addresses.mp_cidr[var.environment.vpc_name]],
        }
        oem-agent-3872 = {
          description = "Allow oem agent ingress from OEM"
          from_port   = "3872"
          to_port     = "3872"
          protocol    = "TCP"
          cidr_blocks = [var.ip_addresses.mp_cidr[var.environment.vpc_name]],
        }
      }
      egress = {
        all-to-oem = {
          description = "Allow all egress to OEM"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = [var.ip_addresses.mp_cidr[var.environment.vpc_name]],
        }
      }
    }
  }
}
