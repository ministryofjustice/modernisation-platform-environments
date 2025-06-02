# resource "aws_vpn_gateway" "vpn_gw" {
#   vpc_id          = data.aws_vpc.shared.id
#   amazon_side_asn = 7224
#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-vpn-gw" }
#   )
# }


# resource "aws_customer_gateway" "cgw_northgate" {
#   count      = local.application_data.accounts[local.environment].northgate_gateway_ip != "" ? 1 : 0
#   bgp_asn    = 64678
#   ip_address = local.application_data.accounts[local.environment].northgate_gateway_ip
#   type       = "ipsec.1"

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-northgate-cgw" },
#   )
# }

# resource "aws_vpn_connection" "vpn_northgate" {
#   count                                = local.application_data.accounts[local.environment].northgate_gateway_ip != "" ? 1 : 0
#   vpn_gateway_id                       = aws_vpn_gateway.vpn_gw.id
#   customer_gateway_id                  = aws_customer_gateway.cgw_northgate[count.index].id
#   type                                 = "ipsec.1"
#   static_routes_only                   = false
#   tunnel1_phase1_encryption_algorithms = ["AES256-GCM-16"]
#   tunnel1_phase1_lifetime_seconds      = 28800
#   tunnel1_phase1_dh_group_numbers      = [24, 21]
#   tunnel1_phase2_dh_group_numbers      = [24, 21]
#   tunnel1_phase2_encryption_algorithms = ["AES256-GCM-16"]
#   tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
#   tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
#   tunnel1_ike_versions                 = ["ikev2"]
#   tunnel1_startup_action               = "add"
#   tunnel2_phase1_encryption_algorithms = ["AES256-GCM-16"]
#   tunnel2_phase1_lifetime_seconds      = 28800
#   tunnel2_phase1_dh_group_numbers      = [24, 21]
#   tunnel2_phase2_dh_group_numbers      = [24, 21]
#   tunnel2_phase2_encryption_algorithms = ["AES256-GCM-16"]
#   tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
#   tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
#   tunnel2_ike_versions                 = ["ikev2"]
#   tunnel2_startup_action               = "add"

#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-northgate-cgw" },
#   )
# }
