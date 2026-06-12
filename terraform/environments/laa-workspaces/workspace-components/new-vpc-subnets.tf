##############################################
### VPC for laa-workspaces (isolated account)
##############################################

resource "aws_vpc" "workspaces" {
  count = local.environment == "development" ? 1 : 0

  cidr_block           = local.application_data.accounts[local.environment].vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-vpc" }
  )
}

##############################################
### Private Subnets (2 AZs minimum for AD)
##############################################

resource "aws_subnet" "private_a" {
  count = local.environment == "development" ? 1 : 0

  vpc_id            = aws_vpc.workspaces[0].id
  cidr_block        = local.application_data.accounts[local.environment].private_subnet_a_cidr
  availability_zone = "eu-west-2a"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-private-eu-west-2a" }
  )
}

resource "aws_subnet" "private_b" {
  count = local.environment == "development" ? 1 : 0

  vpc_id            = aws_vpc.workspaces[0].id
  cidr_block        = local.application_data.accounts[local.environment].private_subnet_b_cidr
  availability_zone = "eu-west-2b"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-private-eu-west-2b" }
  )
}

##############################################
### Dedicated Firewall Subnets
### AWS Network Firewall requires dedicated subnets in each AZ.
##############################################

resource "aws_subnet" "firewall_a" {
  count = local.environment == "development" ? 1 : 0

  vpc_id            = aws_vpc.workspaces[0].id
  cidr_block        = "10.200.200.0/28"
  availability_zone = "eu-west-2a"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-firewall-eu-west-2a" }
  )
}

resource "aws_subnet" "firewall_b" {
  count = local.environment == "development" ? 1 : 0

  vpc_id            = aws_vpc.workspaces[0].id
  cidr_block        = "10.200.200.16/28"
  availability_zone = "eu-west-2b"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-firewall-eu-west-2b" }
  )
}

##############################################
### Route Tables for Private Subnets
##############################################



resource "aws_route_table" "private" {
  count = local.environment == "development" ? 1 : 0

  vpc_id = aws_vpc.workspaces[0].id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-workspaces-private-rt" }
  )
}

resource "aws_route_table_association" "private_a" {
  count = local.environment == "development" ? 1 : 0

  subnet_id      = aws_subnet.private_a[0].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "private_b" {
  count = local.environment == "development" ? 1 : 0

  subnet_id      = aws_subnet.private_b[0].id
  route_table_id = aws_route_table.private[0].id
}


resource "aws_route" "private_a_to_nat" {
  count = local.environment == "development" ? 1 : 0

  route_table_id      = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id      = aws_nat_gateway.main[0].id
}

# resource "aws_route" "private_a_firewall" {
#   count = local.environment == "development" ? 1 : 0

#   route_table_id         = aws_route_table.private[0].id
#   destination_cidr_block = "0.0.0.0/0"
#   vpc_endpoint_id = element([
#     for sync_state in aws_networkfirewall_firewall.workspaces_web_allowlist[0].firewall_status[0].sync_states
#     : sync_state.attachment[0].endpoint_id
#     if sync_state.availability_zone == "eu-west-2a"
#   ], 0)
# }

# resource "aws_route" "private_b_firewall" {
#   count = local.environment == "development" ? 1 : 0

#   route_table_id         = aws_route_table.private[0].id
#   destination_cidr_block = "0.0.0.0/0"
#   vpc_endpoint_id = element([
#     for sync_state in aws_networkfirewall_firewall.workspaces_web_allowlist[0].firewall_status[0].sync_states
#     : sync_state.attachment[0].endpoint_id
#     if sync_state.availability_zone == "eu-west-2b"
#   ], 0)
# }

##############################################
### Route Table for Firewall Subnets -firewall to Internet Gateway
##############################################

resource "aws_route_table" "firewall" {
  count = local.environment == "development" ? 1 : 0

  vpc_id = aws_vpc.workspaces[0].id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main[0].id
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-firewall-rt" }
  )
}



resource "aws_route_table_association" "firewall_a" {
  count = local.environment == "development" ? 1 : 0

  subnet_id      = aws_subnet.firewall_a[0].id
  route_table_id = aws_route_table.firewall[0].id
}

resource "aws_route_table_association" "firewall_b" {
  count = local.environment == "development" ? 1 : 0

  subnet_id      = aws_subnet.firewall_b[0].id
  route_table_id = aws_route_table.firewall[0].id
}

##############################################
### Public Subnets (for ALB)
##############################################

resource "aws_subnet" "public_a" {
  count = local.environment == "development" ? 1 : 0

  vpc_id                  = aws_vpc.workspaces[0].id
  cidr_block              = local.application_data.accounts[local.environment].public_subnet_a_cidr
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-public-eu-west-2a" }
  )
}

resource "aws_subnet" "public_b" {
  count = local.environment == "development" ? 1 : 0

  vpc_id                  = aws_vpc.workspaces[0].id
  cidr_block              = local.application_data.accounts[local.environment].public_subnet_b_cidr
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-public-eu-west-2b" }
  )
}

##############################################
### Internet Gateway
##############################################

resource "aws_internet_gateway" "main" {
  count = local.environment == "development" ? 1 : 0

  vpc_id = aws_vpc.workspaces[0].id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-igw" }
  )
}

##############################################
### Route Table for Public Subnets - nat-gateway to firewall
##############################################


locals {
  firewall_endpoints = {
    for s in aws_networkfirewall_firewall.workspaces_web_allowlist[0].firewall_status[0].sync_states :
    s.availability_zone => s.attachment[0].endpoint_id
  }
}

resource "aws_route_table" "public_a" {
  count = local.environment == "development" ? 1 : 0

  vpc_id = aws_vpc.workspaces[0].id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-public-rt-a" }
  )
}

resource "aws_route_table_association" "public_a" {
  count = local.environment == "development" ? 1 : 0

  subnet_id      = aws_subnet.public_a[0].id
  route_table_id = aws_route_table.public_a[0].id
}




resource "aws_route" "nat_to_firewall_a" {
  count = local.environment == "development" ? 1 : 0

  route_table_id      = aws_route_table.public_a[0].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoints["eu-west-2a"]

}


##############################################
### Route Table for Public Subnets - nat-gateway to firewall
##############################################

resource "aws_route_table" "public_b" {
  count = local.environment == "development" ? 1 : 0


  vpc_id = aws_vpc.workspaces[0].id

    tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-public-rt-b" }
  )
}


resource "aws_route_table_association" "public_b" {
  count = local.environment == "development" ? 1 : 0

  subnet_id      = aws_subnet.public_b[0].id
  route_table_id = aws_route_table.public_b[0].id
}


resource "aws_route" "nat_to_firewall_b" {
  count = local.environment == "development" ? 1 : 0

  route_table_id      = aws_route_table.public_b[0].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoints["eu-west-2b"]

}