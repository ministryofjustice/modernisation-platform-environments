# locals {
#   cloud_platform_ranges = [  ]
# }
locals {
  # Skip test and preprod environments
  create_resources = contains(["development", "production"], local.environment)

  portals = {
    "external_1" = "laa-workspaces-web-external-1"
    "external_2" = "laa-workspaces-web-external-2"
  }

  # Use new VPC in production, shared VPC in other environments
  vpc_id = local.environment == "production" ? data.aws_vpc.secure_browser[0].id : data.aws_vpc.shared.id

  # Use new VPC subnets in production, shared VPC subnets in other environments
  subnet_ids = local.environment == "production" ? concat(
    data.aws_subnets.secure_browser_private_a[0].ids,
    data.aws_subnets.secure_browser_private_b[0].ids
    ) : [
    data.aws_subnet.private_aza.id,
    data.aws_subnet.private_azc.id
  ]

  # Environment-specific application URLs
  pui_url                = local.environment == "production" ? "ccms-pui.laa.service.justice.gov.uk" : "ccms-pui.laa-development.modernisation-platform.service.justice.gov.uk"
  oia_url                = local.environment == "production" ? "ccms-opa.laa.service.justice.gov.uk" : "ccms-opa.laa-development.modernisation-platform.service.justice.gov.uk"
  laa_sign_in_url        = local.environment == "production" ? "laa-sign-in.external-identity.service.justice.gov.uk" : "portal-laa.dev.external-identity.service.justice.gov.uk"
  legal_aid_services_url = local.environment == "production" ? "your-legal-aid-services.service.justice.gov.uk" : "dev.your-legal-aid-services.service.justice.gov.uk"
}