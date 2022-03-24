resource "aws_instance" "cjip-server" {
  depends_on                  = [aws_security_group.ingestion_server]
  instance_type               = "t3.large"
  ami                         = local.application_data.accounts[local.environment].suprig05-ami
  vpc_security_group_ids      = [aws_security_group.ingestion_server.id]
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
      Name = "root-block-device-cjip-${local.application_name}"
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
      Name = "cjip-${local.application_name}"
    }
  )
}


resource "aws_ebs_volume" "cjip-disk1" {
  depends_on        = [aws_instance.cjip-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].suprig05-disk-1-snapshot

  tags = merge(
    local.tags,
    {
      Name = "cjip-disk1-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "cjip-disk1" {
  depends_on   = [aws_instance.cjip-server]
  device_name  = "xvdk"
  force_detach = true
  volume_id    = aws_ebs_volume.cjip-disk1.id
  instance_id  = aws_instance.cjip-server.id
}
