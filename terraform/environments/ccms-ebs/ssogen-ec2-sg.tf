resource "aws_security_group" "ssogen_sg" {
  name        = "ssogen-sg-${local.environment}"
  description = "Security group for SSOGEN EC2 (WebLogic + OHS)"
  vpc_id      = data.aws_vpc.shared.id

  ############################################################
  # ✅ INGRESS RULES — Allow traffic to SSOGEN EC2s
  ############################################################

  # SSH for admin access — WorkSpaces
  ingress {
    description = "SSH from WorkSpaces subnets"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      data.aws_vpc.shared.cidr_block,
      local.application_data.accounts[local.environment].lz_aws_subnet_env,
      local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
      local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env,
    ]
  }

  # WebLogic Admin (7001) — WorkSpaces (private)
  ingress {
    description = "WebLogic 7001 from WorkSpaces subnets"
    from_port   = 7001
    to_port     = 7001
    protocol    = "tcp"
    cidr_blocks = [
      data.aws_vpc.shared.cidr_block,
      local.application_data.accounts[local.environment].lz_aws_subnet_env,
      local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
      local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env,
    ]
  }

  ingress {
    description = "WebLogic 7001 from WorkSpaces NAT IPs"
    from_port   = 7001
    to_port     = 7001
    protocol    = "tcp"
    cidr_blocks = [
      "18.130.39.94/32",
      "35.177.145.193/32",
      "52.56.212.11/32",
      "35.176.254.38/32"
    ]
  }

  # Oracle HTTP Server (7777) — WorkSpaces (private)
  ingress {
    description = "OHS 7777 from WorkSpaces subnets"
    from_port   = 7777
    to_port     = 7777
    protocol    = "tcp"
    cidr_blocks = [
      data.aws_vpc.shared.cidr_block,
      local.application_data.accounts[local.environment].lz_aws_subnet_env,
      local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
      local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env,
    ]
  }

  ingress {
    description = "OHS 7777 from WorkSpaces NAT IPs"
    from_port   = 7777
    to_port     = 7777
    protocol    = "tcp"
    cidr_blocks = [
      "18.130.39.94/32",
      "35.177.145.193/32",
      "52.56.212.11/32",
      "35.176.254.38/32"
    ]
  }

  # Oracle HTTPS (4443) — WorkSpaces (private + NAT)
  ingress {
    description = "OHS 4443 from WorkSpaces subnets"
    from_port   = 4443
    to_port     = 4443
    protocol    = "tcp"
    cidr_blocks = [
      data.aws_vpc.shared.cidr_block,
      local.application_data.accounts[local.environment].lz_aws_subnet_env,
      local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_subnet_env,
      local.application_data.accounts[local.environment].lz_aws_workspace_prod_subnet_env,
    ]
  }

  ingress {
    description = "OHS 4443 from WorkSpaces NAT IPs"
    from_port   = 4443
    to_port     = 4443
    protocol    = "tcp"
    cidr_blocks = [
      "18.130.39.94/32",
      "35.177.145.193/32",
      "52.56.212.11/32",
      "35.176.254.38/32"
    ]
  }

  # WebLogic managed servers (8000–8005) — internal app comms only
  ingress {
    description     = "WebLogic managed servers from EBS App servers"
    from_port       = 8000
    to_port         = 8005
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg_ebsapps.id]
  }

  # Node Manager (5556) — intra-cluster only
  ingress {
    description = "WL Node Manager intra-SG"
    from_port   = 5556
    to_port     = 5556
    protocol    = "tcp"
    self        = true
  }

  ############################################################
  # ✅ EGRESS RULES — Allow SSOGEN to reach dependencies
  ############################################################

  # Oracle LDAP (non-SSL)
  egress {
    description = "Oracle LDAP"
    from_port   = 1389
    to_port     = 1389
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # Oracle LDAP (SSL)
  egress {
    description = "Oracle LDAP SSL"
    from_port   = 1636
    to_port     = 1636
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # Outbound HTTPS
  egress {
    description = "Allow outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound HTTP
  egress {
    description = "Allow outbound HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "ssogen-sg-${local.environment}"
  })
}
