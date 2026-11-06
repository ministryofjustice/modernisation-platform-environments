##############################################
### VPC DHCP Options for Active Directory
###
### NOTE: DHCP options creation requires platform-level permissions
### that are not available in member account roles. Instead, we set
### DNS servers directly in EC2 user_data (see xxx-new-ec2.tf).
###
### If you have platform-level access, uncomment these resources
### and apply them to configure DNS for the entire VPC.
##############################################

# resource "aws_vpc_dhcp_options" "ad_dhcp_options" {
#   count = local.environment == "development" ? 1 : 0
# 
#   domain_name         = local.application_data.accounts[local.environment].ad_directory_name
#   domain_name_servers = aws_directory_service_directory.workspaces_ad[0].dns_ip_addresses
# 
#   tags = merge(
#     local.tags,
#     { "Name" = "${local.application_name}-${local.environment}-ad-dhcp-options" }
#   )
# }
# 
# resource "aws_vpc_dhcp_options_association" "ad_dhcp_association" {
#   count = local.environment == "development" ? 1 : 0
# 
#   vpc_id          = data.terraform_remote_state.workspace_components.outputs.vpc_id
#   dhcp_options_id = aws_vpc_dhcp_options.ad_dhcp_options[0].id
# }

##############################################
### Outputs
##############################################

output "ad_dns_servers" {
  value       = local.environment == "development" ? aws_directory_service_directory.workspaces_ad[0].dns_ip_addresses : null
  description = "AD DNS server IP addresses (10.200.1.245, 10.200.2.11)"
}
