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
### Route Table for Private Subnets
##############################################

resource "aws_route_table" "private" {
  count = local.environment == "development" ? 1 : 0

  vpc_id = aws_vpc.workspaces[0].id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-private-rt" }
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
