resource "aws_vpc" "example" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "example-vpc"
    Environment = "sprinkler"
  }
}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "example-subnet"
  }
}