module "hmcts_sdp_onecrown_network_monitoring" {
  for_each = local.environment_configuration.hmcts_sdp_onecrown_endpoints

  source = "./modules/network-monitoring"

  monitor_name     = "hmcts-sdp-onecrown-${each.key}"
  destination      = each.value.destination
  destination_port = each.value.destination_port
  source_arns      = module.vpc.private_subnet_arns

  tags = local.tags
}
