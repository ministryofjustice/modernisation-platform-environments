#### This file can be used to store locals specific to the member account ####
locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
}
