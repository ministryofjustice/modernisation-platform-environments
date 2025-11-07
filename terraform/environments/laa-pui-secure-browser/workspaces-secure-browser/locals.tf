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

  # Map zone IDs to AZ names
  wssb_supported_zone_ids = ["euw2-az1", "euw2-az2"]

  azid_to_name = {
    for idx, zid in data.aws_availability_zones.available.zone_ids :
    zid => data.aws_availability_zones.available.names[idx]
  }

  wssb_supported_az_names = [
    for zid in local.wssb_supported_zone_ids : local.azid_to_name[zid]
  ]

  # Use new VPC in production, shared VPC in other environments
  vpc_id = local.environment == "production" ? data.aws_vpc.secure_browser[0].id : data.aws_vpc.shared.id

  # Use new VPC subnets in production, shared VPC subnets in other environments
  # Take first subnet from each AZ (WorkSpaces Web requires 2-3 subnets from at least 2 AZs)
  subnet_ids = local.environment == "production" ? flatten([
    for az in local.wssb_supported_az_names : data.aws_subnets.secure_browser_private[az].ids
    ]) : [
    data.aws_subnet.private_aza.id,
    data.aws_subnet.private_azc.id
  ]

  # Environment-specific application URLs
  pui_url                = local.environment == "production" ? "ccms-pui.laa.service.justice.gov.uk" : "ccms-pui.laa-development.modernisation-platform.service.justice.gov.uk"
  oia_url                = local.environment == "production" ? "ccms-opa.laa.service.justice.gov.uk" : "ccms-opa.laa-development.modernisation-platform.service.justice.gov.uk"
  laa_sign_in_url        = local.environment == "production" ? "laa-sign-in.external-identity.service.justice.gov.uk" : "portal-laa.dev.external-identity.service.justice.gov.uk"
  legal_aid_services_url = local.environment == "production" ? "your-legal-aid-services.service.justice.gov.uk" : "dev.your-legal-aid-services.service.justice.gov.uk"
}