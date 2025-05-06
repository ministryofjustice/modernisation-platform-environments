#### This file can be used to store data specific to the member account ####

data "aws_region" "this" {}

data "aws_availability_zones" "available" {
  filter {
    name   = "region-name"
    values = [data.aws_region.this.name]
  }
}

data "aws_vpc" "connected_vpc" {
  cidr_block = local.environment_configuration.connected_vpc_cidr
}
