# locals {
#   cloud_platform_ranges = [  ]
# }
locals {
  portals = {
    "external_1" = "laa-workspaces-web-external-1"
    "external_2" = "laa-workspaces-web-external-2"
  }

  # Use new VPC in production, shared VPC in other environments
  vpc_id = local.environment == "production" ? data.aws_vpc.secure_browser[0].id : data.aws_vpc.shared.id

  # Use new VPC subnets in production, shared VPC subnets in other environments
  subnet_ids = local.environment == "production" ? [
    data.aws_subnet.secure_browser_private_a[0].id,
    data.aws_subnet.secure_browser_private_b[0].id
    ] : [
    data.aws_subnet.private_aza.id,
    data.aws_subnet.private_azc.id
  ]
}