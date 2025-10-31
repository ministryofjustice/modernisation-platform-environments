# Look up the new VPC in production (created by networking component)
data "aws_vpc" "secure_browser" {
  count = local.environment == "production" ? 1 : 0
  tags = {
    "Name" = "laa-production-secure-browser"
  }
}

# Look up subnets in the new VPC for production
data "aws_subnet" "secure_browser_private_a" {
  count = local.environment == "production" ? 1 : 0
  tags = {
    "Name" = "laa-private-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "secure_browser_private_b" {
  count = local.environment == "production" ? 1 : 0
  tags = {
    "Name" = "laa-private-${data.aws_region.current.name}b"
  }
}

# Look up shared VPC subnets for non-production environments
data "aws_subnet" "private_aza" {
  filter {
    name   = "tag:Name"
    values = ["${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-eu-west-2a"]
  }
}

data "aws_subnet" "private_azc" {
  filter {
    name   = "tag:Name"
    values = ["${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-eu-west-2c"]
  }
}
