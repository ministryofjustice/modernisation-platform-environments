##############################################
### VPC Endpoints for Private Subnet Access
###
### Required for EC2 instances in private subnets to:
### - Use SSM Session Manager
### - Retrieve secrets from Secrets Manager
### - Download packages from internet via S3
##############################################

##############################################
### Security Group for VPC Endpoints
##############################################

resource "aws_security_group" "vpc_endpoints" {
  count = local.environment == "development" ? 1 : 0

  name_prefix = "${local.application_name}-${local.environment}-vpce-"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.workspaces[0].id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.workspaces[0].cidr_block]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-vpce-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

##############################################
### SSM VPC Endpoints (for Session Manager)
##############################################

resource "aws_vpc_endpoint" "ssm" {
  count = local.environment == "development" ? 1 : 0

  vpc_id              = aws_vpc.workspaces[0].id
  service_name        = "com.amazonaws.eu-west-2.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a[0].id, aws_subnet.private_b[0].id]
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-ssm-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count = local.environment == "development" ? 1 : 0

  vpc_id              = aws_vpc.workspaces[0].id
  service_name        = "com.amazonaws.eu-west-2.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a[0].id, aws_subnet.private_b[0].id]
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-ssmmessages-endpoint"
    }
  )
}

resource "aws_vpc_endpoint" "ec2messages" {
  count = local.environment == "development" ? 1 : 0

  vpc_id              = aws_vpc.workspaces[0].id
  service_name        = "com.amazonaws.eu-west-2.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a[0].id, aws_subnet.private_b[0].id]
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-ec2messages-endpoint"
    }
  )
}

##############################################
### Secrets Manager VPC Endpoint
##############################################

resource "aws_vpc_endpoint" "secretsmanager" {
  count = local.environment == "development" ? 1 : 0

  vpc_id              = aws_vpc.workspaces[0].id
  service_name        = "com.amazonaws.eu-west-2.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a[0].id, aws_subnet.private_b[0].id]
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-secretsmanager-endpoint"
    }
  )
}

##############################################
### EC2 VPC Endpoint (for EC2 metadata)
##############################################

resource "aws_vpc_endpoint" "ec2" {
  count = local.environment == "development" ? 1 : 0

  vpc_id              = aws_vpc.workspaces[0].id
  service_name        = "com.amazonaws.eu-west-2.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a[0].id, aws_subnet.private_b[0].id]
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-ec2-endpoint"
    }
  )
}

##############################################
### S3 Gateway Endpoint (for package downloads)
### Gateway endpoints are free and allow yum to work
##############################################

resource "aws_vpc_endpoint" "s3" {
  count = local.environment == "development" ? 1 : 0

  vpc_id            = aws_vpc.workspaces[0].id
  service_name      = "com.amazonaws.eu-west-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private[0].id]

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application_name}-${local.environment}-s3-endpoint"
    }
  )
}
