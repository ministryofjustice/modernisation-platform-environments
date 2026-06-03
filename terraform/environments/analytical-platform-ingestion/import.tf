# This file is used to import the existing SG rules into Terraform state.Will be deleted after the import is complete and the state file is updated.

locals {
  sg_rule_ids = {
    "analytical-platform-ingestion-development" = {
      ingress_udp_connected_vpc = "sgr-0e9409b3a1402394f"
      ingress_tcp_connected_vpc = "sgr-08fbca30d2db58e27"
      egress_tcp_resolver1      = "sgr-00095bced315afcb1"
      egress_tcp_resolver2      = "sgr-03b98cdabeaa67c5f"
      egress_udp_resolver1      = "sgr-07109865a194eb192"
      egress_udp_resolver2      = "sgr-08135da9f21631148"
    }
    "analytical-platform-ingestion-production" = {
      ingress_udp_connected_vpc = "sgr-0f519600c12aaebf2"
      ingress_tcp_connected_vpc = "sgr-04fadfb61b71624c6"
      egress_tcp_resolver1      = "sgr-0b13d84ca666b2fd8"
      egress_tcp_resolver2      = "sgr-0ed7fa353d3cd9e7f"
      egress_udp_resolver1      = "sgr-045f1ca051f76fa96"
      egress_udp_resolver2      = "sgr-0858ddf3ab5917c9b"
    }
  }

  current_sg_rule_ids = lookup(local.sg_rule_ids, terraform.workspace, null)
}

import {
  for_each = local.current_sg_rule_ids != null ? { "0" = local.current_sg_rule_ids.ingress_udp_connected_vpc } : {}
  to       = module.connected_vpc_outbound_route53_resolver_endpoint.aws_vpc_security_group_ingress_rule.udp["connected_vpc"]
  id       = each.value
}

import {
  for_each = local.current_sg_rule_ids != null ? { "0" = local.current_sg_rule_ids.ingress_tcp_connected_vpc } : {}
  to       = module.connected_vpc_outbound_route53_resolver_endpoint.aws_vpc_security_group_ingress_rule.tcp["connected_vpc"]
  id       = each.value
}

import {
  for_each = local.current_sg_rule_ids != null ? { "0" = local.current_sg_rule_ids.egress_tcp_resolver1 } : {}
  to       = module.connected_vpc_outbound_route53_resolver_endpoint.aws_vpc_security_group_egress_rule.tcp["moj_service_resolver1"]
  id       = each.value
}

import {
  for_each = local.current_sg_rule_ids != null ? { "0" = local.current_sg_rule_ids.egress_tcp_resolver2 } : {}
  to       = module.connected_vpc_outbound_route53_resolver_endpoint.aws_vpc_security_group_egress_rule.tcp["moj_service_resolver2"]
  id       = each.value
}

import {
  for_each = local.current_sg_rule_ids != null ? { "0" = local.current_sg_rule_ids.egress_udp_resolver1 } : {}
  to       = module.connected_vpc_outbound_route53_resolver_endpoint.aws_vpc_security_group_egress_rule.udp["moj_service_resolver1"]
  id       = each.value
}

import {
  for_each = local.current_sg_rule_ids != null ? { "0" = local.current_sg_rule_ids.egress_udp_resolver2 } : {}
  to       = module.connected_vpc_outbound_route53_resolver_endpoint.aws_vpc_security_group_egress_rule.udp["moj_service_resolver2"]
  id       = each.value
}