##############################################
### Route53 Hosted Zone for Isolated Account
###
### Creates local Route53 zone since this account
### doesn't use shared core-vpc networking
##############################################

resource "aws_route53_zone" "external" {
  name = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-external-zone"
    }
  )
}

# Note: NS delegation records need to be created in the parent zone
# (modernisation-platform.service.justice.gov.uk in core-network-services)
# for external DNS resolution to work
