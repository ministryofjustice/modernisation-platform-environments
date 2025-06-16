locals {

  security_groups_filter = flatten([
    var.options.enable_hmpps_domain ? ["ad_join"] : []
  ])

  ad_netbios_name = contains(["development", "test"], var.environment.environment) ? "azure" : "hmpp"

  security_groups = {

    ad_join = {
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
        icmp = {
          description = "Allow ICMP egress"
          from_port   = 8
          to_port     = 0
          protocol    = "ICMP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        dns_udp = {
          description = "Allow DNS UDP egress"
          from_port   = 53
          to_port     = 53
          protocol    = "UDP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        dns_tcp = {
          description = "Allow DNS TCP egress"
          from_port   = 53
          to_port     = 53
          protocol    = "TCP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        kerberos_udp = {
          description = "Allow Kerberos UDP egress"
          from_port   = 88
          to_port     = 88
          protocol    = "UDP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        kerberos_tcp = {
          description = "Allow Kerberos TCP egress"
          from_port   = 88
          to_port     = 88
          protocol    = "TCP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        ntp_udp = {
          description = "Allow NTP UDP egress"
          from_port   = 123
          to_port     = 123
          protocol    = "UDP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        rpc_tcp = {
          description = "Allow RPC TCP egress"
          from_port   = 135
          to_port     = 135
          protocol    = "TCP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        netbios_udp = {
          description = "Allow Netbios UDP egress"
          from_port   = 137
          to_port     = 139
          protocol    = "UDP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        netbios_tcp = {
          description = "Allow Netbios TCP egress"
          from_port   = 137
          to_port     = 139
          protocol    = "TCP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        ldap_udp = {
          description = "Allow Ldap UDP egress"
          from_port   = 389
          to_port     = 389
          protocol    = "UDP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        ldap_tcp = {
          description = "Allow Ldap TCP egress"
          from_port   = 389
          to_port     = 389
          protocol    = "TCP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        smb_tcp = {
          description = "Allow SMB TCP egress"
          from_port   = 445
          to_port     = 445
          protocol    = "TCP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        kerberos_password_change_udp = {
          description = "Allow Kerberos Password Change UDP egress"
          from_port   = 464
          to_port     = 464
          protocol    = "UDP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        kerberos_password_change_tcp = {
          description = "Allow Kerberos Password Change TCP egress"
          from_port   = 464
          to_port     = 464
          protocol    = "TCP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        ldaps_tcp = {
          description = "Allow Ldaps TCP egress"
          from_port   = 636
          to_port     = 636
          protocol    = "TCP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        ldap_global_catalog_tcp = {
          description = "Allow Ldaps Global Catalog TCP egress"
          from_port   = 3268
          to_port     = 3269
          protocol    = "TCP"
          cidr_blocks = var.ip_addresses.active_directory_cidrs[local.ad_netbios_name].domain_controllers
        }
        adws_tcp = {
          description = "Allow ADWS TCP egress"
          from_port   = 9389
          to_port     = 9389
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
    }
  }
}
