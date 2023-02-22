resource "aws_instance" "oem_db" {
  ami                         = "ami-0c6f19670d053404e"
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name
  instance_type               = local.application_data.accounts[local.environment].ec2_oem_instance_type_db
  key_name                    = local.application_data.accounts[local.environment].key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  user_data = base64encode(templatefile("./templates/oem-user-data.sh", {
    efs_id   = aws_efs_file_system.oem-db-efs.id
    hostname = "ccms-oem-db"
  }))
  vpc_security_group_ids = [aws_security_group.oem_db_security_group.id]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 12
    volume_type           = "gp2"
  }

  volume_tags = merge(tomap(
    { "Name" = "${local.application_name_oem}-db-root" }
  ), local.tags)

  tags = merge(tomap(
    { "Name" = lower(format("ec2-%s-%s-db", local.application_name_oem, local.environment)) }
  ), local.tags)

  lifecycle {
    ignore_changes = [
      volume_tags,
      user_data
    ]
  }
}

resource "aws_ebs_volume" "oem_db_volume_ccms_oem_inst" {
  availability_zone = "eu-west-2a"
  size              = 50
  type              = "gp2"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap(
    { "Name" = "${local.application_name_oem}-db-ccms-oem-inst" }
  ), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id,
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_ccms_oem_inst" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_ccms_oem_inst.id
  device_name = "/dev/sdg"
}

resource "aws_ebs_volume" "oem_db_volume_ccms_oem_dbf" {
  availability_zone = "eu-west-2a"
  size              = 500
  type              = "gp2"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap(
    { "Name" = "${local.application_name_oem}-db-ccms-oem-dbf" }
  ), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id,
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_ccms_oem_dbf" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_ccms_oem_dbf.id
  device_name = "/dev/sdh"
}

resource "aws_ebs_volume" "oem_db_volume_swap" {
  availability_zone = "eu-west-2a"
  size              = 32
  type              = "gp2"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap(
    { "Name" = "${local.application_name_oem}-db-swap" }
  ), local.tags)
}

resource "aws_volume_attachment" "oem_db_volume_swap" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_swap.id
  device_name = "/dev/sdi"
}


resource "aws_security_group" "oem_db_security_group" {
  name_prefix = "${local.application_name_oem}-db-server-sg"
  description = "controls access to the ebs app server"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = [
      "10.202.0.0/20", "10.200.0.0/20", "10.200.16.0/20",
    ]
  }

  ingress {
    protocol  = "tcp"
    from_port = 1159
    to_port   = 1159
    cidr_blocks = [
      "10.202.0.0/20", "10.200.0.0/20", "10.200.16.0/20",
    ]
  }

  ingress {
    protocol  = "tcp"
    from_port = 1521
    to_port   = 1521
    cidr_blocks = [
      "10.202.0.0/20", "10.200.0.0/20", "10.200.16.0/20",
    ]
  }

  ingress {
    protocol  = "tcp"
    from_port = 1830
    to_port   = 1849
    cidr_blocks = [
      "10.202.0.0/20", "10.200.0.0/20", "10.200.16.0/20",
    ]
  }

  ingress {
    protocol  = "tcp"
    from_port = 2049
    to_port   = 2049
    cidr_blocks = [
      "10.202.0.0/20", "10.200.0.0/20", "10.200.16.0/20",
    ]
  }

  ingress {
    protocol  = "tcp"
    from_port = 3872
    to_port   = 3872
    cidr_blocks = [
      "10.202.0.0/20", "10.200.0.0/20", "10.200.16.0/20",
    ]
  }

  ingress {
    protocol  = "tcp"
    from_port = 4889
    to_port   = 4889
    cidr_blocks = [
      "10.202.0.0/20", "10.200.0.0/20", "10.200.16.0/20",
    ]
  }

  ingress {
    protocol  = "tcp"
    from_port = 7101
    to_port   = 7101
    cidr_blocks = [
      "10.202.0.0/20", "10.200.0.0/20", "10.200.16.0/20",
    ]
  }

  ingress {
    protocol  = "tcp"
    from_port = 7799
    to_port   = 7799
    cidr_blocks = [
      "10.202.0.0/20", "10.200.0.0/20", "10.200.16.0/20",
    ]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = local.tags
}
