resource "aws_security_group" "ec2_security_dc" {
  description = "Domain Controller Communication"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    protocol    = "-1"
    description = "Open all outbound ports"
    from_port   = 0
    to_port     = 0
    #tfsec:ignore:AWS009
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name = "ec2_security_dc"
  }
}

resource "aws_security_group" "ec2_security_adc" {
  description = "Nimbus Communication"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    protocol    = "-1"
    description = "Open all outbound ports"
    from_port   = 0
    to_port     = 0
    #tfsec:ignore:AWS009
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  tags = {
    Name = "ec2_security_adc"
  }
}

resource "aws_security_group" "ec2_security_rdp" {
  description = "RDP Communication"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    protocol    = "-1"
    description = "Open all outbound ports"
    from_port   = 0
    to_port     = 0
    #tfsec:ignore:AWS009
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  tags = {
    Name = "ec2_security_RDP"
  }
}

resource "aws_security_group" "ec2_security_sf" {
  description = "SF Communication"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    protocol    = "-1"
    description = "Open all outbound ports"
    from_port   = 0
    to_port     = 0
    #tfsec:ignore:AWS009
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  tags = {
    Name = "ec2_security_SF"
  }
}


resource "aws_security_group" "ec2_security_samba" {
  description = "Samba Communication"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    protocol    = "-1"
    description = "Open all outbound ports"
    from_port   = 0
    to_port     = 0
    #tfsec:ignore:AWS009
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  tags = {
    Name = "ec2_security_samba"
  }
}


resource "aws_security_group" "ec2_security_citrix" {
  description = "citrix Communication"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    protocol    = "-1"
    description = "Open all outbound ports"
    from_port   = 0
    to_port     = 0
    #tfsec:ignore:AWS009
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  tags = {
    Name = "ec2_security_citrix"
  }
}
