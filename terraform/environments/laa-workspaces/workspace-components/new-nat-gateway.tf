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
### NAT Gateway routes are handled by the private and firewall route tables
### so all private subnet traffic is routed through Network Firewall endpoints
### and the firewall subnets can egress via the NAT gateway.
##############################################
