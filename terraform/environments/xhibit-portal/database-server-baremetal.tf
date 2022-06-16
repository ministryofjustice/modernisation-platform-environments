#another trigger
resource "aws_instance" "database-server-baremetal" {
  # Used to only allow the bare metal server to deploy in prod
  count                       = local.only_in_production
  depends_on                  = [aws_security_group.sms_server]
  instance_type               = "c5d.metal"
  ami                         = local.application_data.accounts[local.environment].suprig01-baremetal-ami
  vpc_security_group_ids      = [aws_security_group.sms_server.id]
  monitoring                  = false
  associate_public_ip_address = false
  ebs_optimized               = false
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.ben.key_name


  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted   = true
    volume_size = 300
    tags = {
      Name = "root-block-device-database-baremetal-${local.application_name}"
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
      # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]

    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "database-baremetal-${local.application_name}"
    }
  )
}


resource "aws_ebs_volume" "database-baremetal-disk1" {
  count             = local.only_in_production
  depends_on        = [aws_instance.database-server-baremetal]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true
  size              = 4000

  tags = merge(
    local.tags,
    {
      Name = "database-baremetal-disk1-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-baremetal-disk1" {
  count        = local.only_in_production
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdl"
  force_detach = true
  volume_id    = aws_ebs_volume.database-baremetal-disk1[count.index].id
  instance_id  = aws_instance.database-server-baremetal[count.index].id
}


resource "aws_network_interface" "baremetal-database-network-access" {
  count           = local.only_in_production
  depends_on      = [aws_instance.database-server-baremetal]
  subnet_id       = data.aws_subnet.private_az_a.id
  security_groups = [aws_security_group.app_servers.id]

  attachment {
    instance     = aws_instance.database-server-baremetal[count.index].id
    device_index = 1
  }
}
