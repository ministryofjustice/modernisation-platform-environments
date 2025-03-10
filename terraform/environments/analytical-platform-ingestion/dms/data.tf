#### This file can be used to store data specific to the member account ####

data "aws_availability_zones" "available" {
    filter {
        name = "region-name"
        values = [ "eu-west-2" ]
    }
}

data "aws_vpc" "connected_vpc" {
    cidr_block = local.environment_configuration.connected_vpc_cidr
}
