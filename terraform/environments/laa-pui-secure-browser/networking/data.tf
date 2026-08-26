data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ec2_transit_gateway" "modernisation_platform" {
  count = local.environment == "production" ? 1 : 0
  filter {
    name   = "options.amazon-side-asn"
    values = ["64589"]
  }
}
