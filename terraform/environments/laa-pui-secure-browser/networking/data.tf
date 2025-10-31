data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ec2_transit_gateway" "moj_tgw" {
  id = "tgw-026162f1ba39ce704"
}
