##############################################################
### MoJ Transit Gateway for Transit Gateway VPC attachments
##############################################################
data "aws_ec2_transit_gateway" "moj_tgw" {
  id = try(local.application_variables.accounts[local.environment].transit_gateway_id, null)
}


##############################################################
### Data sources for Route53 hosted zones
###
### These are commented out in platform_data.tf.
### Declared here for use by ACM, Route53 and SES resources.
##############################################################

data "aws_route53_zone" "external" {
  provider = aws.core-vpc

  name         = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

data "aws_route53_zone" "network-services" {
  provider = aws.core-network-services

  name         = "modernisation-platform.service.justice.gov.uk."
  private_zone = false
}
