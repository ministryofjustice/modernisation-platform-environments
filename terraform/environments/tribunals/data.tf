#### This file can be used to store data specific to the member account ####
data "aws_route53_zone" "production_zone" {
  provider     = aws.core-network-services
  name         = "tribunals.gov.uk."
  private_zone = false
}

data "aws_subnet" "public_subnets_b" {
  vpc_id            = data.aws_vpc.shared.id
  availability_zone = "eu-west-2b"
  filter {
    name   = "tag:Name"
    values = ["*-public-eu-west-2b"]
  }
}