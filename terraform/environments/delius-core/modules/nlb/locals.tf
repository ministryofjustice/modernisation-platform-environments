locals {
  ldap_name     = "${var.env_name}-ldap"
  ldap_nlb_name = "${local.ldap_name}-nlb"
  ldap_nlb_tags = merge(var.tags,{ Name = local.ldap_nlb_name })

  ldap_protocol = "TCP"
  ldap_port = 389
}