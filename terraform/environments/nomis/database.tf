data "aws_subnet" "data_az_a" {
  vpc_id = local.vpc_id
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-data-${local.region}a"
  }
}

# Security Groups
resource "aws_security_group" "db_server" {
  description = "Configure Oracle database access"
  name        = "db-server-${local.application_name}"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH from Bastion"
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = ["${module.bastion_linux.bastion_private_ip}/32"]
  }

  ingress {
    description     = "DB access from weblogic (private subnet)"
    from_port       = "1521"
    to_port         = "1521"
    protocol        = "TCP"
    security_groups = [aws_security_group.weblogic_server.id]
  }

  egress {
    description      = "allow all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "db-server-${local.application_name}"
    }
  )
}

##### EC2 ####
data "aws_ami" "db_image" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["nomis_db-2021-09-24*"] # pinning image for now
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "db_server" {
  instance_type               = "t3.medium" # TODO: replace with "d2.xlarge" to match required spec.
  ami                         = data.aws_ami.db_image.id
  monitoring                  = true
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.id
  ebs_optimized               = true
  subnet_id                   = data.aws_subnet.private_az_a.id # data.aws_subnet.data_az_a.id put here whilst testing install steps
  user_data                   = file("./templates/cloudinit.cfg")
  vpc_security_group_ids      = [aws_security_group.db_server.id]

  # block devices defined in custom image
  # root_block_device {
  #   delete_on_termination = true
  #   encrypted             = true
  #   volume_size           = 30
  # }

  lifecycle {
    ignore_changes = [
      # This prevents clobbering the tags of attached EBS volumes. See
      # [this bug][1] in the AWS provider upstream.
      #
      # [1]: https://github.com/terraform-providers/terraform-provider-aws/issues/770
      volume_tags,
      #user_data,         # Prevent changes to user_data from destroying existing EC2s
      root_block_device, # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]
  }

  tags = merge(
    local.tags,
    {
      Name = "db-server-${local.application_name}"
    }
  )
}

resource "aws_ebs_volume" "asm_disk" {
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true
  size              = 100

  tags = merge(
    local.tags,
    {
      Name = "db-server-${local.application_name}-asm-disk"
    }
  )
}

resource "aws_volume_attachment" "asm_disk" {
  device_name = "/dev/sde"
  volume_id   = aws_ebs_volume.asm_disk.id
  instance_id = aws_instance.db_server.id
}

resource "aws_ebs_volume" "asm_disk_temp" {
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true
  size              = 10

  tags = merge(
    local.tags,
    {
      Name = "db-server-${local.application_name}-asm-disk-temp"
    }
  )
}

resource "aws_volume_attachment" "asm_disk_temp" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.asm_disk_temp.id
  instance_id = aws_instance.db_server.id
}