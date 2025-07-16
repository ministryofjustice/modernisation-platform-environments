module "vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=25322b6b6be69db6cca7f167d7b0e5327156a595" # v5.8.1

  name = "${local.application_name}-${local.environment}"
  azs  = local.availability_zones
  cidr = local.application_data.accounts[local.environment].vpc_cidr
  #  private_subnets = local.private_subnets

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = false
  create_flow_log_cloudwatch_log_group = false
  create_flow_log_cloudwatch_iam_role  = false
  flow_log_max_aggregation_interval    = 60

  tags = local.tags
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${local.application_name}-${local.environment}-igw"
  }
}

# Create an EIP for a NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = merge(
    local.tags, {
      Name = "${local.application_name}-${local.environment}-nat-eip"
    }
  )
}

#  Create a NAT Gateway 
resource "aws_nat_gateway" "juniper_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.vsrx_subnets["vSRX01 Management Range"].id

  tags = merge(
    local.tags, {
      Name = "${local.application_name}-${local.environment}-nat-gateway"
    }
  )
}

locals {
  vsrx_subnet_config = {
    "vSRX01 Management Range"    = { cidr = "10.100.105.0/24", az = "eu-west-2a", eni_ip = ["10.100.105.100"] }
    "vSRX01 PSK External Range"  = { cidr = "10.100.110.0/24", az = "eu-west-2a", eni_ip = ["10.100.110.100"] }
    "vSRX01 Cert External Range" = { cidr = "10.100.115.0/24", az = "eu-west-2a", eni_ip = ["10.100.115.100"] }
    "vSRX01 Internal Range"      = { cidr = "10.100.120.0/24", az = "eu-west-2a", eni_ip = ["10.100.120.100"] }
    "Juniper Management & KMS"   = { cidr = "10.100.50.0/24", az = "eu-west-2a" }
    "vSRX02 Management Range"    = { cidr = "10.100.205.0/24", az = "eu-west-2b", eni_ip = ["10.100.205.100"] }
    "vSRX02 PSK External Range"  = { cidr = "10.100.210.0/24", az = "eu-west-2b", eni_ip = ["10.100.210.100"] }
    "vSRX02 Cert External Range" = { cidr = "10.100.215.0/24", az = "eu-west-2b", eni_ip = ["10.100.215.100"] }
    "vSRX02 Internal Range"      = { cidr = "10.100.220.0/24", az = "eu-west-2b", eni_ip = ["10.100.220.100"] }
  }
}

resource "aws_subnet" "vsrx_subnets" {
  for_each = local.vsrx_subnet_config

  vpc_id                  = module.vpc.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    Name = each.key
  })
}

# Create Network Interfaces for vSRX01 (eu-west-2a)
resource "aws_network_interface" "vsrx01_enis" {
  for_each = {
    "vSRX01 Management Interface"    = "vSRX01 Management Range"
    "vSRX01 PSK External Interface"  = "vSRX01 PSK External Range"
    "vSRX01 Cert External Interface" = "vSRX01 Cert External Range"
    "vSRX01 Internal Interface"      = "vSRX01 Internal Range"
  }

  subnet_id         = aws_subnet.vsrx_subnets[each.value].id
  private_ips       = local.vsrx_subnet_config[each.value].eni_ip # Assign the specified private IP to the ENI
  source_dest_check = false                                       # Disable Source/Destination Check
  security_groups   = each.key == "vSRX01 Internal Interface" ? [aws_security_group.internal_sg.id] : [aws_security_group.external_sg.id]

  tags = merge(local.tags, {
    Name = each.key
  })
}

# Create Network Interfaces for vSRX02 (eu-west-2b)
resource "aws_network_interface" "vsrx02_enis" {
  for_each = {
    "vSRX02 Management Interface"    = "vSRX02 Management Range"
    "vSRX02 PSK External Interface"  = "vSRX02 PSK External Range"
    "vSRX02 Cert External Interface" = "vSRX02 Cert External Range"
    "vSRX02 Internal Interface"      = "vSRX02 Internal Range"
  }

  subnet_id         = aws_subnet.vsrx_subnets[each.value].id
  private_ips       = local.vsrx_subnet_config[each.value].eni_ip # Assign the specified private IP to the ENI
  source_dest_check = false                                       # Disable Source/Destination Check
  security_groups   = each.key == "vSRX02 Internal Interface" ? [aws_security_group.internal_sg.id] : [aws_security_group.external_sg.id]

  tags = merge(local.tags, {
    Name = each.key
  })
}


# Create the route table
resource "aws_route_table" "juniper_route_table" {
  vpc_id = module.vpc.vpc_id

  tags = merge(local.tags, {
    Name = "Juniper firewalls route table"
  })
}

# Add a route to the Internet Gateway
resource "aws_route" "juniper_igw_route" {
  route_table_id         = aws_route_table.juniper_route_table.id
  destination_cidr_block = "0.0.0.0/0"                  # Route all internet-bound traffic
  gateway_id             = aws_internet_gateway.main.id # Reference to the IGW
}


# Attach subnets to the route table (excluding "Juniper Management & KMS")
resource "aws_route_table_association" "juniper_route_table_association" {
  for_each = {
    for k, v in aws_subnet.vsrx_subnets : k => v.id if k != "Juniper Management & KMS"
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.juniper_route_table.id
}

# Create route table for Juniper Management & KMS subnet
resource "aws_route_table" "juniper_management_route_table" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.juniper_nat_gateway.id
  }
  route {
    cidr_block           = "10.0.22.0/24"
    network_interface_id = aws_network_interface.vsrx01_enis["vSRX01 Internal Interface"].id
  }
  route {
    cidr_block           = "10.0.23.0/24"
    network_interface_id = aws_network_interface.vsrx01_enis["vSRX01 Internal Interface"].id
  }
  route {
    cidr_block           = "10.0.24.0/24"
    network_interface_id = aws_network_interface.vsrx02_enis["vSRX02 Internal Interface"].id
  }
  route {
    cidr_block           = "10.0.25.0/24"
    network_interface_id = aws_network_interface.vsrx02_enis["vSRX02 Internal Interface"].id
  }
  tags = merge(local.tags, {
    Name = "Juniper Management Route Table"
  })
}

# Create a route table association for the "Juniper Management & KMS" subnet
resource "aws_route_table_association" "juniper_management_route_table_association" {
  subnet_id      = aws_subnet.vsrx_subnets["Juniper Management & KMS"].id
  route_table_id = aws_route_table.juniper_management_route_table.id
}

# Create Elastic IPs
resource "aws_eip" "eips" {
  count = 6
  tags = {
    Name = [
      "vSRX1 Mgt Interface",
      "vSRX1 PSK Interface",
      "vSRX1 Cert Interface",
      "vSRX2 Mgt Interface",
      "vSRX2 PSK Interface",
      "vSRX2 Cert Interface"
    ][count.index]
  }
  lifecycle {
    prevent_destroy = true
  }
}

# Associate the first 3 EIPs to vsrx01's network interfaces
resource "aws_eip_association" "vsrx01_eip_associations" {
  count = 3
  network_interface_id = [
    aws_network_interface.vsrx01_enis["vSRX01 Management Interface"].id,
    aws_network_interface.vsrx01_enis["vSRX01 PSK External Interface"].id,
    aws_network_interface.vsrx01_enis["vSRX01 Cert External Interface"].id
  ][count.index]
  allocation_id = aws_eip.eips[count.index].id
}

# Associate the next 3 EIPs to vsrx02's network interfaces
resource "aws_eip_association" "vsrx02_eip_associations" {
  count = 3
  network_interface_id = [
    aws_network_interface.vsrx02_enis["vSRX02 Management Interface"].id,
    aws_network_interface.vsrx02_enis["vSRX02 PSK External Interface"].id,
    aws_network_interface.vsrx02_enis["vSRX02 Cert External Interface"].id
  ][count.index]
  allocation_id = aws_eip.eips[count.index + 3].id
}