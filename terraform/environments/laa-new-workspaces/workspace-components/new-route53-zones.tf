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

##############################################
### NS Delegation - Manual Step Required
##############################################
# After applying this, add NS delegation in core-network-services:
#
# In modernisation-platform/terraform/environments/core-network-services/,
# create a file named laa-new-workspaces-delegation.tf with:
#
# resource "aws_route53_record" "laa_new_workspaces_development_ns" {
#   zone_id = data.aws_route53_zone.modernisation_platform.zone_id
#   name    = "laa-development.modernisation-platform.service.justice.gov.uk"
#   type    = "NS"
#   ttl     = 300
#   records = [
#     # Get these values from terraform output external_zone_name_servers
#     # They look like: ns-123.awsdns-12.com, ns-456.awsdns-45.net, etc.
#   ]
# }
#
# Repeat for production environment if needed.
