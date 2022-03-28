variable "additional_tags" {
  default     = {}
  description = "Additional resource tags"
  type        = map(string)
}

resource "aws_instance" "citrix_adc_instance" {
  ami           = "ami-0dd0aa051b3fc4e4b"
  instance_type = "m5.xlarge"
  key_name      = aws_key_pair.windowskey.key_name
  monitoring                  = true
  ebs_optimized               = true

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 30
    kms_key_id  = aws_kms_key.this.arn
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  network_interface {
    network_interface_id = aws_network_interface.public_interface.id
    device_index         = 0
  }

  tags = {
    Name = "NPS-COR-A-ADC01"
    ROLE = "Citrix Netscaler ADC VPX"
  }
}


resource "aws_network_interface" "public_interface" {
  subnet_id       = data.aws_subnet.public_az_a.id
  security_groups = [aws_security_group.citrix_adc_security_group.id]

  tags = {
    Name        = "Citrix ADC VPX External Interface"
    Description = "External Interface for Citrix ADC"
  }
}

resource "aws_network_interface" "private_interface" {
  subnet_id       = data.aws_subnet.private_subnets_a.id
  security_groups = [aws_security_group.citrix_adc_security_group.id]

  attachment {
    instance     = aws_instance.citrix_adc_instance.id
    device_index = 1
  }

  tags = {
    Name        = "Private Network Internal Interface"
    Description = "Private Interface for Citrix ADC"
  }
}

resource "aws_network_interface" "data_interface" {
  subnet_id       = data.aws_subnet.data_subnets_a.id
  security_groups = [aws_security_group.citrix_adc_security_group.id]

  attachment {
    instance     = aws_instance.citrix_adc_instance.id
    device_index = 2
  }

  tags = {
    Name        = "Data Network Internal Interface"
    Description = "Data Network Interface for Citrix ADC"
  }
}



resource "aws_eip" "citrix_eip_pub" {
  vpc               = true
  network_interface = aws_network_interface.public_interface.id
  depends_on        = [aws_instance.citrix_adc_instance]

  tags = {
    Name = "Elastic IpAddress for Citrix"
  }
}

resource "aws_security_group" "citrix_adc_security_group" {
  #checkov:skip=CKV_AWS_24: Attaching using Module
  #checkov:skip=CKV_AWS_25: Attaching using Module
  name        = "citrix-adc-security-group"
  description = "controls access to citrix"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    protocol    = "-1"
    description = "Open all port"
    from_port   = 0
    to_port     = 0
    #tfsec:ignore:AWS008
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  tags = merge(
    var.additional_tags,
    {
      Name = "citrix-adc-security-group-loadbalancer"
    }
  )
}
