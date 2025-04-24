#another trigger
resource "aws_instance" "database-server" {
  # checkov:skip=CKV_AWS_135: "Ensure that EC2 is EBS optimized"
  # checkov:skip=CKV2_AWS_41: "Ensure an IAM role is attached to EC2 instance"
  depends_on                  = [aws_security_group.app_servers]
  instance_type               = "t2.medium"
  ami                         = local.application_data.accounts[local.environment].suprig01-ami
  vpc_security_group_ids      = [aws_security_group.app_servers.id]
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
    encrypted   = true
    volume_size = 64
    tags = {
      Name = "root-block-device-database-${local.application_name}"
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
      Name = "database-${local.application_name}"
    }
  )
}


resource "aws_ebs_volume" "database-disk1" {

  # checkov:skip=CKV_AWS_189: "Ensure EBS Volume is encrypted by KMS using a customer managed Key (CMK)"

  depends_on        = [aws_instance.database-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].suprig01-disk-1-snapshot

  tags = merge(
    local.tags,
    {
      Name = "database-disk1-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-disk1" {
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdl"
  force_detach = true
  volume_id    = aws_ebs_volume.database-disk1.id
  instance_id  = aws_instance.database-server.id
}

resource "aws_ebs_volume" "database-disk2" {

  # checkov:skip=CKV_AWS_189: "Ensure EBS Volume is encrypted by KMS using a customer managed Key (CMK)"

  depends_on        = [aws_instance.database-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].suprig01-disk-2-snapshot

  tags = merge(
    local.tags,
    {
      Name = "database-disk2-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-disk2" {
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdm"
  force_detach = true
  volume_id    = aws_ebs_volume.database-disk2.id
  instance_id  = aws_instance.database-server.id
}


resource "aws_ebs_volume" "database-disk3" {

  # checkov:skip=CKV_AWS_189: "Ensure EBS Volume is encrypted by KMS using a customer managed Key (CMK)"

  depends_on        = [aws_instance.database-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].suprig01-disk-3-snapshot

  tags = merge(
    local.tags,
    {
      Name = "database-disk3-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-disk3" {
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdn"
  force_detach = true
  volume_id    = aws_ebs_volume.database-disk3.id
  instance_id  = aws_instance.database-server.id
}

resource "aws_ebs_volume" "database-disk4" {

  # checkov:skip=CKV_AWS_189: "Ensure EBS Volume is encrypted by KMS using a customer managed Key (CMK)"

  depends_on        = [aws_instance.database-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].suprig01-disk-4-snapshot

  tags = merge(
    local.tags,
    {
      Name = "database-disk4-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-disk4" {
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdo"
  force_detach = true
  volume_id    = aws_ebs_volume.database-disk4.id
  instance_id  = aws_instance.database-server.id
}

resource "aws_ebs_volume" "database-disk5" {

  # checkov:skip=CKV_AWS_189: "Ensure EBS Volume is encrypted by KMS using a customer managed Key (CMK)"

  depends_on        = [aws_instance.database-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].suprig01-disk-5-snapshot

  tags = merge(
    local.tags,
    {
      Name = "database-disk5-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-disk5" {
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdy"
  force_detach = true
  volume_id    = aws_ebs_volume.database-disk5.id
  instance_id  = aws_instance.database-server.id
}


resource "aws_ebs_volume" "database-disk6" {

  # checkov:skip=CKV_AWS_189: "Ensure EBS Volume is encrypted by KMS using a customer managed Key (CMK)"

  depends_on        = [aws_instance.database-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  #snapshot_id = local.application_data.accounts[local.environment].suprig01-disk-6-snapshot

  size = 300

  tags = merge(
    local.tags,
    {
      Name = "database-disk6-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-disk6" {
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdf"
  force_detach = true
  volume_id    = aws_ebs_volume.database-disk6.id
  instance_id  = aws_instance.database-server.id
}

resource "aws_ebs_volume" "database-disk7" {

  # checkov:skip=CKV_AWS_189: "Ensure EBS Volume is encrypted by KMS using a customer managed Key (CMK)"

  depends_on        = [aws_instance.database-server]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  size = 300

  tags = merge(
    local.tags,
    {
      Name = "database-disk7-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "database-disk7" {
  depends_on   = [aws_instance.database-server]
  device_name  = "xvdp"
  force_detach = true
  volume_id    = aws_ebs_volume.database-disk7.id
  instance_id  = aws_instance.database-server.id
}
