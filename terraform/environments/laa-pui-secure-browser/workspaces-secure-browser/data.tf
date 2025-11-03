# Look up availability zones to map zone IDs to names
data "aws_availability_zones" "available" {
  state = "available"
}

# Get current AWS region
data "aws_region" "current" {}

# Get current caller identity
data "aws_caller_identity" "current" {}

# Look up subnet details for CIDR blocks (used in security group rules)
data "aws_subnet" "secure_browser_subnets" {
  for_each = local.create_resources ? toset(local.subnet_ids) : toset([])
  id       = each.value
}

# Look up the new VPC in production (created by networking component)
data "aws_vpc" "secure_browser" {
  count = local.environment == "production" ? 1 : 0
  tags = {
    "Name" = "laa-production-secure-browser"
  }
}

# Look up subnets in the new VPC for production
data "aws_subnets" "secure_browser_private" {
  for_each = local.environment == "production" ? toset(local.wssb_supported_az_names) : toset([])

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.secure_browser[0].id]
  }

  filter {
    name   = "availability-zone"
    values = [each.value]
  }

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-secure-browser-private-*"
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
