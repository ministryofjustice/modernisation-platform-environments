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
    description     = "SSH from Bastion"
    from_port       = "22"
    to_port         = "22"
    protocol        = "TCP"
    security_groups = [module.bastion_linux.bastion_security_group]
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
    values = [local.application_data.accounts[local.environment].database_ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  volume_size = {
    "/dev/sdb" = 100,
    "/dev/sdc" = 100,
    "/dev/sde" = 100,
    "/dev/sdf" = 100,
    "/dev/sds" = 16
  }
}

resource "aws_instance" "db_server" {
  instance_type               = "r5.xlarge"
  ami                         = data.aws_ami.db_image.id
  monitoring                  = true
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_common_profile.id
  ebs_optimized               = true
  subnet_id                   = data.aws_subnet.data_az_a.id
  user_data                   = file("./templates/database_init.sh")
  vpc_security_group_ids      = [aws_security_group.db_server.id]
  key_name                    = aws_key_pair.ec2-user.key_name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 30
  }

  dynamic "ebs_block_device" {
    for_each = [for bdm in data.aws_ami.db_image.block_device_mappings : bdm if bdm.device_name != data.aws_ami.db_image.root_device_name]
    iterator = device
    content {
      device_name = device.value["device_name"]
      iops        = device.value["ebs"]["iops"]
      snapshot_id = device.value["ebs"]["snapshot_id"]
      volume_size = lookup(local.volume_size, device.value["device_name"], device.value["ebs"]["volume_size"])
      volume_type = device.value["ebs"]["volume_type"]
    }
  }

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
      Name      = "db-server-${local.application_name}"
      component = "data"
      os_type   = "Linux (RHEL 7.9)"
      always_on = "false"
    }
  )
}