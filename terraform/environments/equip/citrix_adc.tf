resource "aws_instance" "citrix_adc_instance" {
  ami           = "ami-0dd0aa051b3fc4e4b"
#  instance_type = "t4g.large"
  instance_type = "c5.xlarge"
  key_name      = aws_key_pair.windowskey.key_name
  monitoring    = true
  ebs_optimized = true

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
    network_interface_id = aws_network_interface.public.id
    device_index         = 0
  }

  tags = {
    Name = "Citrix ADC VPX"
  }
}

resource "aws_network_interface" "public" {
  subnet_id       = data.aws_subnet.public_az_a.id
  security_groups = [aws_security_group.citrix_adc_security_group.id]

  tags = {
    Name        = "Public interface"
    Description = "Public Interface for Citrix ADC"
  }
}

resource "aws_network_interface" "private" {
  subnet_id       = data.aws_subnet.private_subnets_a.id
  security_groups = [aws_security_group.citrix_adc_security_group.id]

  attachment {
    instance     = aws_instance.citrix_adc_instance.id
    device_index = 1
  }

  tags = {
    Name        = "Private Interface"
    Description = "Private Interface for Citrix ADC"
  }
}

resource "aws_eip" "citrix_eip_pub" {
  vpc               = true
  network_interface = aws_network_interface.public.id

  depends_on = [aws_instance.citrix_adc_instance]

  tags = {
    Name = "Elastic IpAddress for Citrix"
  }
}

resource "aws_security_group" "citrix_adc_security_group" {
  name = "citrix-adc-security-group"
  description = "controls access to citrix"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    protocol    = "tcp"
    description = "Open the server port"
    from_port   = 80
    to_port     = 80
    #tfsec:ignore:AWS008
    cidr_blocks = ["0.0.0.0/0" ]
  }

  ingress {
    protocol    = "tcp"
    description = "Open the SSL port"
    from_port   = 443
    to_port     = 443
    #tfsec:ignore:AWS008
    cidr_blocks = ["0.0.0.0/0" ]
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
    var.tags,
    {
      Name = "citrix-adc-security-group-loadbalancer-security-group"
    }
  )
}


