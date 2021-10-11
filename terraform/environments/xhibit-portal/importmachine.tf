# # Security Groups
# resource "aws_security_group" "importmachine" {
#   description = "Configure importmachine access - ingress should be only from Bastion"
#   name        = "importmachine-${local.application_name}"
#   vpc_id      = local.vpc_id

#   ingress {
#     description = "SSH from Bastion"
#     from_port   = 0
#     to_port     = "3389"
#     protocol    = "TCP"
#     cidr_blocks = ["${module.bastion_linux.bastion_private_ip}/32"]
#   }

#   egress {
#     description      = "allow all"
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

# }

# data "aws_subnet" "private_az_a" {
#   tags = {
#     Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}a"
#   }
# }

# resource "aws_instance" "importmachine" {
#   instance_type               = "t2.large"
#   ami                         = "ami-0a0502ffd782e9b12"
#   associate_public_ip_address = false
#   # iam_instance_profile        = "ssm-ec2-profile"
#   monitoring             = false
#   vpc_security_group_ids = [aws_security_group.importmachine.id]
#   subnet_id              = data.aws_subnet.private_az_a.id
#   ebs_optimized          = true

#   metadata_options {
#     http_tokens   = "required"
#     http_endpoint = "enabled"
#   }

#   root_block_device {
#     encrypted = true
#   }

# }

# resource "aws_ebs_volume" "vmimage_disk" {
#   availability_zone = "${local.region}a"
#   type              = "gp2"
#   encrypted         = true
#   size              = 6000
# }

# resource "aws_volume_attachment" "vmimage_disk" {
#   device_name = "/dev/sde"
#   volume_id   = aws_ebs_volume.vmimage_disk.id
#   instance_id = aws_instance.importmachine.id
# }


# get shared subnet-set private (az (a) subnet)
data "aws_subnet" "private_az_a" {
  # provider = aws.share-host
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}a"
  }
}


# Security Groups
resource "aws_security_group" "importmachine" {
  description = "Configure importmachine access - ingress should be only from Bastion"
  name        = "importmachine-${local.application_name}"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH from Bastion"
    from_port   = 0
    to_port     = "3389"
    protocol    = "TCP"
    cidr_blocks = ["${module.bastion_linux.bastion_private_ip}/32"]
  }

  egress {
    description      = "allow all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}


##### EC2 ####
data "aws_ami" "win2003" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "win2003" {
  instance_type               = "t4g.large"
  ami                         = data.aws_ami.win2003.id
  vpc_security_group_ids      = [aws_security_group.importmachine.id]
  monitoring                  = true
  associate_public_ip_address = false
  ebs_optimized               = true
  subnet_id                   = data.aws_subnet.private_az_a.id

  lifecycle {
    ignore_changes = [
      # This prevents clobbering the tags of attached EBS volumes. See
      # [this bug][1] in the AWS provider upstream.
      #
      # [1]: https://github.com/terraform-providers/terraform-provider-aws/issues/770
      volume_tags,
      #user_data,         # Prevent changes to user_data from destroying existing EC2s
      root_block_device,
      # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]
  }

  tags = merge(
  local.tags,
  {
    Name = "win2003-${local.application_name}"
  }
  )
}

resource "aws_ebs_volume" "disk_xvdf" {
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true
  size              = 400

  tags = merge(
  local.tags,
  {
    Name = "win2003-${local.application_name}-disk"
  }
  )
}

resource "aws_volume_attachment" "disk_xvdf" {
  device_name = "xvdf"
  volume_id   = aws_ebs_volume.disk_xvdf.id
  instance_id = aws_instance.win2003.id
}
