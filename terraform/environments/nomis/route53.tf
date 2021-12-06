#------------------------------------------------------------------------------
# Datasources for Route 53 Zones
# The actual records are declared with the relevant resources
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Internal Zone
#------------------------------------------------------------------------------
data "aws_route53_zone" "internal" {
  provider = aws.core-vpc

  name         = "${local.vpc_name}-${local.environment}.modernisation-platform.internal."
  private_zone = true
}

#------------------------------------------------------------------------------
# External Zone
#------------------------------------------------------------------------------
data "aws_route53_zone" "external" {
  provider = aws.core-vpc

  name         = "${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk."
  private_zone = false
}