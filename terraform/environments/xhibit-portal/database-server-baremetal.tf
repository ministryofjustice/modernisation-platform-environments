# While this is called database-server-baremetal, this actually holds the database and the app server.
# We need permissions to run terraform mv to eventually update the naming.
resource "aws_instance" "database-server-baremetal" {
  # checkov:skip=CKV_AWS_135: "Ensure that EC2 is EBS optimized"
  # checkov:skip=CKV2_AWS_41: "Ensure an IAM role is attached to EC2 instance"
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
      Name = "root-block-device-baremetal-${local.application_name}"
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
      Name = "baremetal-${local.application_name}"
    }
  )
}

# Database disk and network
resource "aws_ebs_volume" "database-baremetal-disk1" {

  # checkov:skip=CKV_AWS_189: "Ensure EBS Volume is encrypted by KMS using a customer managed Key (CMK)"

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
  depends_on   = [aws_instance.database-server-baremetal]
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
  tags = merge(
    local.tags,
    {
      Name = "database-baremetal-eni-${local.application_name}"
    }
  )

  attachment {
    instance     = aws_instance.database-server-baremetal[count.index].id
    device_index = 1
  }
}

# App disk and network
resource "aws_ebs_volume" "app-baremetal-disk2" {

  # checkov:skip=CKV_AWS_189: "Ensure EBS Volume is encrypted by KMS using a customer managed Key (CMK)"

  count             = local.only_in_production
  depends_on        = [aws_instance.database-server-baremetal]
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true
  size              = 2000

  tags = merge(
    local.tags,
    {
      Name = "app-baremetal-disk2-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "app-baremetal-disk2" {
  count        = local.only_in_production
  depends_on   = [aws_instance.database-server-baremetal]
  device_name  = "xvdm"
  force_detach = true
  volume_id    = aws_ebs_volume.app-baremetal-disk2[count.index].id
  instance_id  = aws_instance.database-server-baremetal[count.index].id
}


resource "aws_network_interface" "baremetal-app-network-access" {
  count           = local.only_in_production
  depends_on      = [aws_instance.database-server-baremetal]
  subnet_id       = data.aws_subnet.private_az_a.id
  security_groups = [aws_security_group.app_servers.id]

  tags = merge(
    local.tags,
    {
      Name = "app-baremetal-eni-${local.application_name}"
    }
  )

  attachment {
    instance     = aws_instance.database-server-baremetal[count.index].id
    device_index = 2
  }
}

