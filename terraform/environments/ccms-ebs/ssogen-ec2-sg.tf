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

  # WebLogic/OHS HTTPS access
  ingress {
    description = "WebLogic HTTPS"
    from_port   = 4443
    to_port     = 4444
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

  # # Allow outbound HTTPS for patching, time sync, etc.
  # egress {
  #   description = "Allow outbound HTTPS"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # Allow internal communication within VPC
  egress {
    description = "Allow all outbound to internal network"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  tags = merge(local.tags, {
    Name = "ssogen-sg-${local.environment}"
  })
}
