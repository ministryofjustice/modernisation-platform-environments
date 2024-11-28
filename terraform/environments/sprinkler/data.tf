#### This file can be used to store data specific to the member account ####

data "aws_caller_identity" "core_vpc" {
  provider = aws.core-vpc
}

data "aws_caller_identity" "core_network_services" {
  provider = aws.core-network-services
}

data "aws_caller_identity" "us_east_1" {
  provider = aws.us-east-1
}
