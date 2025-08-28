resource "aws_security_group" "ssogen_sg" {
  name        = "ssogen-sg-${local.environment}"
  description = "Security group for SSOGEN EC2 (WebLogic + OHS)"
  vpc_id      = data.aws_vpc.shared.id

  ############################################################
  # ✅ INGRESS RULES — Allow traffic to SSOGEN EC2s
  ############################################################

  # SSH for admin access (restrict to internal or bastion)
  ingress {
    description = "Allow SSH from internal network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

 # WebLogic/OHS HTTP access (e.g. from EBS, LASSIE)
  ingress {
    description = "WebLogic HTTP"
    from_port   = 8000
    to_port     = 8005
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # Oracle HTTP Server (7777)
  ingress {
    description = "Oracle HTTP Server"
    from_port   = 7777
    to_port     = 7777
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # WebLogic/OHS HTTPS access
  ingress {
    description = "WebLogic HTTPS"
    from_port   = 4443
    to_port     = 4444
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # WebLogic Node Manager (5556)
  ingress {
    description = "Oracle WL Node Manager"
    from_port   = 5556
    to_port     = 5556
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # Allow inbound from EBS apps via SG reference
  ingress {
    description     = "Allow calls from EBS App servers"
    from_port       = 8000
    to_port         = 8005
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg_ebsapps.id]
  }

  # WebLogic (7001) — allow from internal network
  ingress {
    description = "Allow WebLogic HTTP from internal network"
    from_port   = 7001
    to_port     = 7001
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # WebLogic (7001) — allow from WorkSpaces NAT IPs (Non-Prod + Prod)
  ingress {
    description = "Allow WebLogic HTTP from WorkSpaces NAT IPs"
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

  ############################################################
  # ✅ EGRESS RULES — Allow SSOGEN to reach dependencies
  ############################################################

  # Allow outbound to Oracle LDAP (non-SSL)
  egress {
    description = "Oracle LDAP"
    from_port   = 1389
    to_port     = 1389
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # Allow outbound to Oracle LDAP (SSL)
  egress {
    description = "Oracle LDAP SSL"
    from_port   = 1636
    to_port     = 1636
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  # Allow outbound HTTPS for patching, time sync, etc.
  egress {
    description = "Allow outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound HTTP (yum updates, etc.)
  egress {
    description = "Allow outbound HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound WebLogic (7001) back to internal and WorkSpaces NAT IPs
  egress {
    description = "Allow WebLogic HTTP responses"
    from_port   = 7001
    to_port     = 7001
    protocol    = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "18.130.39.94/32",
      "35.177.145.193/32",
      "52.56.212.11/32",
      "35.176.254.38/32"
    ]
  }

  tags = merge(local.tags, {
    Name = "ssogen-sg-${local.environment}"
  })
}
