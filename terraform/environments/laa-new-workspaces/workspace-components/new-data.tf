##############################################################
### MoJ Transit Gateway for Transit Gateway VPC attachments
##############################################################
data "aws_ec2_transit_gateway" "moj_tgw" {
  id = try(local.application_data.accounts[local.environment].transit_gateway_id, null)
}


##############################################################
### Data sources for Route53 hosted zones
###
### External zone is created locally in new-route53-zones.tf
### Network-services zone is in platform_data.tf (from cloud-platform)
##############################################################

data "aws_route53_zone" "external" {
  name         = aws_route53_zone.external.name
  private_zone = false

  depends_on = [aws_route53_zone.external]
}
