data "aws_ami" "jumpserver_image" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["jumpserver-windows"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "jumpserver_windows" {
  instance_type               = "t2.medium"
  ami                         = data.aws_ami.jumpserver_image.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_common_profile.id
  monitoring                  = false
  vpc_security_group_ids      = [aws_security_group.jumpserver-windows.id]
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = "jumpserver-windows"
  root_block_device {
    encrypted = true
  }

  tags = merge(
    local.tags,
    {
      Name    = "jumpserver_windows"
      os_type = "Windows 2019"
      creator = "Packer" # Temporary Tag: Allows me to delete the instance using the CLI
    }
  )
}

resource "aws_security_group" "jumpserver-windows" {
  description = "Configure Windows jumpserver egress"
  name        = "jumpserver-windows-${local.application_name}"
  vpc_id      = local.vpc_id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
