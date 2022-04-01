data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_subnet" "private_az_a" {
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}a"
  }
}

resource "aws_security_group" "ppud_data_transfer" {
  description = "Security group for the ppud data transer instance"
  name        = "data-transfer-${local.application_name}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "ppud_data_transfer_ssh_ingress" {
  security_group_id = aws_security_group.ppud_data_transfer.id

  description = "ppud_data_transfer_ssh_ingress"
  type        = "ingress"
  from_port   = "22"
  to_port     = "22"
  protocol    = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ppud_data_transfer_http_egress" {
  security_group_id = aws_security_group.ppud_data_transfer.id

  description = "ppud_data_transfer_http_egress"
  type        = "egress"
  from_port   = "80"
  to_port     = "80"
  protocol    = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ppud_data_transfer_https_egress" {
  security_group_id = aws_security_group.ppud_data_transfer.id

  description = "ppud_data_transfer_https_egress"
  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_key_pair" "doakley" {
  key_name   = "doakley"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEU5QgCe9tiwCmZxZIx0E6n9It3Xb9oO5bu30rGRv9Vm darren.oakley@digital.justice.gov.uk"
}

resource "aws_instance" "ppud_data_transfer" {
  instance_type               = "t3.micro"
  ami                         = data.aws_ami.ubuntu.id
  vpc_security_group_ids      = [aws_security_group.ppud_data_transfer.id]
  monitoring                  = true
  associate_public_ip_address = false
  ebs_optimized               = true
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.doakley.key_name

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted   = true
    volume_size = 100
    volume_type = "standard"
    tags = {
      Name = "root-block-device-data-transfer-${local.application_name}"
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "data-transfer-${local.application_name}"
    }
  )
}
