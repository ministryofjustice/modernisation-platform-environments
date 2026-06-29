##############################################
### VPC for laa-new-workspaces (isolated account)
##############################################

resource "aws_vpc" "workspaces" {

  cidr_block           = local.application_data.accounts[local.environment].vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-vpc" }
  )
}

##############################################
### Private Subnets
##############################################

resource "aws_subnet" "private_a" {

  vpc_id            = aws_vpc.workspaces.id
  cidr_block        = local.application_data.accounts[local.environment].private_subnet_a_cidr
  availability_zone = "eu-west-2a"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-private-eu-west-2a" }
  )
}

resource "aws_subnet" "private_b" {

  vpc_id            = aws_vpc.workspaces.id
  cidr_block        = local.application_data.accounts[local.environment].private_subnet_b_cidr
  availability_zone = "eu-west-2b"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-private-eu-west-2b" }
  )
}

##############################################
### Route Table for Private Subnets
##############################################

resource "aws_route_table" "private_a" {

  vpc_id = aws_vpc.workspaces.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-private-a-rt" }
  )
}

resource "aws_route_table" "private_b" {

  vpc_id = aws_vpc.workspaces.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-private-b-rt" }
  )
}

resource "aws_route_table_association" "private_a" {

  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {

  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

resource "aws_route" "private_a_firewall" {

  route_table_id         = aws_route_table.private_a.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id = local.firewall_endpoints["eu-west-2a"]
}

resource "aws_route" "private_b_firewall" {

  route_table_id         = aws_route_table.private_b.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id = local.firewall_endpoints["eu-west-2b"]
}

##############################################
### Public Subnets (for ALB)
##############################################

resource "aws_subnet" "public_a" {

  vpc_id                  = aws_vpc.workspaces.id
  cidr_block              = local.application_data.accounts[local.environment].public_subnet_a_cidr
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-public-eu-west-2a" }
  )
}

resource "aws_subnet" "public_b" {

  vpc_id                  = aws_vpc.workspaces.id
  cidr_block              = local.application_data.accounts[local.environment].public_subnet_b_cidr
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-public-eu-west-2b" }
  )
}

##############################################
### NAT Public Subnets 
##############################################

resource "aws_subnet" "nat_a" {

  vpc_id            = aws_vpc.workspaces.id
  cidr_block        = local.application_data.accounts[local.environment].nat_subnet_a_cidr
  availability_zone = "eu-west-2a"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-nat-eu-west-2a" }
  )
}

resource "aws_subnet" "nat_b" {

  vpc_id            = aws_vpc.workspaces.id
  cidr_block        = local.application_data.accounts[local.environment].nat_subnet_b_cidr
  availability_zone = "eu-west-2b"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-nat-eu-west-2b" }
  )
}

resource "aws_route_table" "nat" {

  vpc_id = aws_vpc.workspaces.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-nat-rt" }
  )
}

resource "aws_route_table_association" "nat_a" {

  subnet_id      = aws_subnet.nat_a.id
  route_table_id = aws_route_table.nat.id
}

# No NAT in subnet B

# resource "aws_route_table_association" "nat_b" {

#   subnet_id      = aws_subnet.nat_b.id
#   route_table_id = aws_route_table.nat.id
# }

resource "aws_route" "nat_igw" {

  route_table_id         = aws_route_table.nat.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id      = aws_internet_gateway.main.id
  
}

resource "aws_route" "nat_firewall_a" {

  route_table_id         = aws_route_table.nat.id
  destination_cidr_block = local.application_data.accounts[local.environment].private_subnet_a_cidr
  vpc_endpoint_id = local.firewall_endpoints["eu-west-2a"]
  
}

resource "aws_route" "nat_firewall_b" {

  route_table_id         = aws_route_table.nat.id
  destination_cidr_block = local.application_data.accounts[local.environment].private_subnet_b_cidr
  vpc_endpoint_id = local.firewall_endpoints["eu-west-2b"]
  
}

##############################################
### Firewall Subnets
##############################################

resource "aws_subnet" "firewall_a" {

  vpc_id            = aws_vpc.workspaces.id
  cidr_block        = local.application_data.accounts[local.environment].firewall_subnet_a_cidr
  availability_zone = "eu-west-2a"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-firewall-eu-west-2a" }
  )
}

resource "aws_subnet" "firewall_b" {

  vpc_id            = aws_vpc.workspaces.id
  cidr_block        = local.application_data.accounts[local.environment].firewall_subnet_b_cidr
  availability_zone = "eu-west-2b"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-firewall-eu-west-2b" }
  )
}

resource "aws_route_table" "firewall" {

  vpc_id = aws_vpc.workspaces.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-firewall-rt" }
  )
}

resource "aws_route_table_association" "firewall_a" {

  subnet_id      = aws_subnet.firewall_a.id
  route_table_id = aws_route_table.firewall.id
}

resource "aws_route_table_association" "firewall_b" {

  subnet_id      = aws_subnet.firewall_b.id
  route_table_id = aws_route_table.firewall.id
}

resource "aws_route" "firewall_nat" {

  route_table_id         = aws_route_table.firewall.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
  
}

##############################################
### Internet Gateway
##############################################

resource "aws_internet_gateway" "main" {

  vpc_id = aws_vpc.workspaces.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-igw" }
  )
}

###########################################################
### Route Table for Public Subnets - containing ALB
###########################################################

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.workspaces.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-public-rt" }
  )
}

resource "aws_route_table_association" "public_a" {

  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {

  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}


##############################################
### Transit Gateway Attachment
##############################################

resource "aws_ec2_transit_gateway_vpc_attachment" "moj_tgw" {
  transit_gateway_id                 = data.aws_ec2_transit_gateway.moj_tgw.id
  vpc_id                             = aws_vpc.workspaces.id
  subnet_ids                         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_referencing_support = "enable"

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-tgw-attachment" }
  )
}