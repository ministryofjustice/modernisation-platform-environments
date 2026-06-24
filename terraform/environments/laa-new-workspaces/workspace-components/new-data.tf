##############################################################
### MoJ Transit Gateway for Transit Gateway VPC attachments
##############################################################
data "aws_ec2_transit_gateway" "moj_tgw" {
  id = try(local.application_data.accounts[local.environment].transit_gateway_id, null)
}
