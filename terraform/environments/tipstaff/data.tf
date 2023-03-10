#### This file can be used to store data specific to the member account ####

# Default VPC and subnet data
data "aws_vpc" "default" {
  filter {
    name   = "vpc-id"
    values = ["vpc-01a6f475362d4d67d"]
  }
}

//Access subnet of the default VPC
data "aws_subnets" "default_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}