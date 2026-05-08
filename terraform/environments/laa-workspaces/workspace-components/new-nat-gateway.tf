##############################################
### NAT Gateway for Private Subnet Internet Access
###
### Required for EC2 instances in private subnets to:
### - Download packages from internet (yum, pip)
### - Install LinOTP from external repositories
### - Download EPEL and other third-party repos
###
### Cost: ~$32/month + data transfer
##############################################

##############################################
### Elastic IP for NAT Gateway
##############################################

resource "aws_eip" "nat" {
  count = local.environment == "development" ? 1 : 0

  domain = "vpc"

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-nat-eip"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

##############################################
### NAT Gateway (in public subnet)
##############################################

resource "aws_nat_gateway" "main" {
  count = local.environment == "development" ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public_a[0].id

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-nat"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

##############################################
### Add NAT Gateway Route to Private Route Table
##############################################

resource "aws_route" "private_nat_gateway" {
  count = local.environment == "development" ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}
