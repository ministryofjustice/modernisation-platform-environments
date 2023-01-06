resource "aws_instance" "iisrelay-server" {

  depends_on                  = [aws_security_group.iisrelay_server]
  instance_type               = "t3.large"
  ami                         = local.application_data.accounts[local.environment].iisrelay-ami
  vpc_security_group_ids      = [aws_security_group.iisrelay_server.id]
  monitoring                  = true
  associate_public_ip_address = false
  ebs_optimized               = false
  subnet_id                   = data.aws_subnet.public_az_a.id
  key_name                    = aws_key_pair.george.key_name

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
    tags = {
      Name = "root-block-device-iisrelay-server-${local.application_name}"
    }
  }

  lifecycle {
    ignore_changes = [
      # This prevents clobbering the tags of attached EBS volumes. See
      # [this bug][1] in the AWS provider upstream.
      #
      # [1]: https://github.com/terraform-providers/terraform-provider-aws/issues/770
      associate_public_ip_address,
      volume_tags,
      #user_data,         # Prevent changes to user_data from destroying existing EC2s
      #root_block_device,
      # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "iisrelay-${local.application_name}"
    }
  )
}

resource "aws_ebs_volume" "iisrelay-disk1" {
  depends_on        = [aws_instance.iisrelay-server]
  availability_zone = "${local.region}a"
  type              = "gp3"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].iisrelay-disk-1-snapshot

  tags = merge(
    local.tags,
    {
      Name = "iisrelay-disk1-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "iisrelay-disk1" {
  depends_on   = [aws_instance.iisrelay-server]
  device_name  = "xvdl"
  force_detach = true
  volume_id    = aws_ebs_volume.iisrelay-disk1.id
  instance_id  = aws_instance.iisrelay-server.id
}




resource "aws_ebs_volume" "iisrelay-disk2" {
  depends_on        = [aws_instance.iisrelay-server]
  availability_zone = "${local.region}a"
  type              = "gp3"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].infra6-disk-2-snapshot

  tags = merge(
    local.tags,
    {
      Name = "iisrelay-disk2-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "iisrelay-disk2" {
  depends_on   = [aws_instance.iisrelay-server]
  device_name  = "xvdm"
  force_detach = true
  volume_id    = aws_ebs_volume.iisrelay-disk2.id
  instance_id  = aws_instance.iisrelay-server.id
}