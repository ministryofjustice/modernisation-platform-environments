##############################################
### NAT Gateway for Private Subnet Internet Access
###
### Required for EC2 instances in private subnets to:
### - Download packages from internet (yum, pip)
### - Install LinOTP from external repositories
### - Download EPEL and other third-party repos
###
##############################################

##############################################
### Elastic IP for NAT Gateway
##############################################

resource "aws_eip" "nat" {

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

  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.nat_a.id

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-nat"
    }
  )

  depends_on = [aws_internet_gateway.main]
}
