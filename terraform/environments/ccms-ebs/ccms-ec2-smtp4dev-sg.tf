resource "aws_security_group" "smtp4dev_mock_server_sg" {
  name        = "ccms-ec2-smtp4dev-sg"
  description = "Security group for smtp4dev mock server"
  vpc_id      = data.aws_vpc.shared.id

  # Inbound rules
  ingress {
    description = "This rule is used for AWS Workspace vm"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.200.0.0/20"]
  }

  ingress {
    description = "This rule is used for smtp4dev for mail messages"
    from_port   = 2525
    to_port     = 2525
    protocol    = "tcp"
    cidr_blocks = ["10.26.60.223/32"]
  }

  ingress {
    description = "POP3 (Port 110)"
    from_port   = 110
    to_port     = 110
    protocol    = "tcp"
    cidr_blocks = ["10.26.60.223/32"]
  }

  # Outbound rule
  egress {
    description = "HTTPS outbound (Port 443)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ccms-ec2-smtp4dev-sg"
  }
}