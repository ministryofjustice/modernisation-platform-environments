#### This file can be used to store data specific to the member account ####

#data "aws_ami" "mis_windows" {
#  most_recent = true
#  owners      = ["self"]
#
#  filter {
#    name   = "name"
#    values = ["^delius_mis_windows_server"]
#  }
#}

data "aws_subnets" "shared-private-a" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private*a"
  }
}

data "aws_subnets" "shared-private-b" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private*b"
  }
}

data "aws_subnets" "shared-private-c" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private*c"
  }
}
