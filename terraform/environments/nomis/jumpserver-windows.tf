data "aws_subnet" "private_az_a" {
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}a"
  }
}

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
  #checkov:skip=CKV_AWS_135:skip "Ensure that EC2 is EBS optimized" as not supported by t2 instances.
  # This can probably be moved to a t3 instance. Review next time instance type is changed.  
  instance_type               = "t2.medium"
  ami                         = data.aws_ami.jumpserver_image.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_common_profile.id
  monitoring                  = false
  vpc_security_group_ids      = [aws_security_group.jumpserver-windows.id]
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = "jumpserver-windows"
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp3"
  }

  tags = merge(
    local.tags,
    {
      Name       = "jumpserver_windows"
      os_type    = "Windows"
      os_version = "2019"
      always_on  = "false"
      creator    = "Packer" # Temporary Tag: Allows me to delete the instance using the CLI
    }
  )
}

resource "aws_security_group" "jumpserver-windows" {
  description = "Configure Windows jumpserver egress"
  name        = "jumpserver-windows-${local.application_name}"
  vpc_id      = local.vpc_id
  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:AWS009
    cidr_blocks = ["0.0.0.0/0"]
  }
}
