resource "aws_instance" "build-server" {
  depends_on                  = [aws_security_group.build_server]
  instance_type               = "t2.medium"
  ami                         = local.application_data.accounts[local.environment].buildserver-ami
  vpc_security_group_ids      = [aws_security_group.build_server.id]
  monitoring                  = false
  associate_public_ip_address = false
  ebs_optimized               = false
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.george.key_name


  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
    tags = {
      Name = "root-block-device-build-${local.application_name}"
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
  }

  tags = merge(
    local.tags,
    {
      Name = "build-${local.application_name}"
    }
  )
}


resource "aws_ebs_volume" "build-disk1" {
  depends_on        = [aws_instance.build-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].buildserver-disk-1-snapshot

  tags = merge(
    local.tags,
    {
      Name = "build-disk1-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "build-disk1" {
  depends_on   = [aws_instance.build-server]
  device_name  = "xvdk"
  force_detach = true
  volume_id    = aws_ebs_volume.build-disk1.id
  instance_id  = aws_instance.build-server.id
}
