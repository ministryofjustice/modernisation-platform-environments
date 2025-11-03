# HMCTS SDP
module "hmcts_sdp_network_monitoring" {
  for_each = local.environment_configuration.hmcts_sdp_endpoints

  source = "./modules/network-monitoring"

  monitor_name     = "hmcts-sdp-${each.key}"
  destination      = each.value.destination
  destination_port = each.value.destination_port
  source_arns      = local.private_subnet_arns
  tags             = local.tags
}

# HMCTS SDP OneCrown
module "hmcts_sdp_onecrown_network_monitoring" {
  for_each = local.environment_configuration.hmcts_sdp_onecrown_endpoints

  source = "./modules/network-monitoring"

  monitor_name     = "hmcts-sdp-onecrown-${each.key}"
  destination      = each.value.destination
  destination_port = each.value.destination_port
  source_arns      = local.private_subnet_arns

  tags = local.tags
}

# Cloud Platform
data "dns_a_record_set" "cloud_platform_internal" {
  for_each = local.environment_configuration.cloud_platform_endpoints

  host = each.value.destination
}

locals {
  cloud_platform_endpoints_flattened = merge([
    for environment, configuration in local.environment_configuration.cloud_platform_endpoints : {
      for idx, addr in data.dns_a_record_set.cloud_platform_internal[environment].addrs :
      "${environment}-${idx}" => {
        environment      = environment
        destination      = addr
        destination_port = configuration.destination_port
      }
    }
  ]...)
}

module "cloud_platform_internal_network_monitoring" {
  for_each = local.cloud_platform_endpoints_flattened

  source = "./modules/network-monitoring"

  monitor_name     = "cloud-platform-internal-${each.value.environment}-${replace(each.value.destination, ".", "-")}"
  destination      = each.value.destination
  destination_port = each.value.destination_port
  source_arns      = local.private_subnet_arns

  tags = local.tags
}
