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
  user_data = base64encode(templatefile("./templates/oem-user-data-db.sh", {
    efs_id   = aws_efs_file_system.oem-db-efs.id
    hostname = "ccms-oem-db"
  }))
  vpc_security_group_ids = [aws_security_group.oem_db_security_group.id]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    iops                  = 3000
    volume_size           = 12
    volume_type           = "gp3"
  }

  volume_tags = merge(tomap(
    { "Name" = "${local.application_name}-db-root" }
  ), local.tags)

  tags = merge(tomap(
    { "Name" = lower(format("ec2-%s-%s-db", local.application_name, local.environment)) }
  ), local.tags)

  lifecycle {
    ignore_changes = [
      volume_tags,
      user_data
    ]
  }
}

resource "aws_ebs_volume" "oem_db_volume_swap" {
  availability_zone = "eu-west-2a"
  depends_on        = [resource.aws_instance.oem_db]
  encrypted         = true
  size              = 32
  type              = "gp3"

  tags = merge(tomap(
    { "Name" = "${local.application_name}-db-swap" }
  ), local.tags)
}

resource "aws_volume_attachment" "oem_db_volume_swap" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_swap.id
  device_name = "/dev/sdb"
}

resource "aws_ebs_volume" "oem_db_volume_ccms_oem_app" {
  availability_zone = "eu-west-2a"
  depends_on        = [resource.aws_instance.oem_db]
  encrypted         = true
  size              = 50
  type              = "gp3"

  tags = merge(tomap(
    { "Name" = "${local.application_name}-db-mnt-oem-app" }
  ), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_ccms_oem_app" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_ccms_oem_app.id
  device_name = "/dev/sdc"
}

resource "aws_ebs_volume" "oem_db_volume_ccms_oem_inst" {
  availability_zone = "eu-west-2a"
  depends_on        = [resource.aws_instance.oem_db]
  encrypted         = true
  size              = 50
  type              = "gp3"

  tags = merge(tomap(
    { "Name" = "${local.application_name}-db-mnt-oem-inst" }
  ), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_ccms_oem_inst" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_ccms_oem_inst.id
  device_name = "/dev/sdd"
}

resource "aws_ebs_volume" "oem_db_volume_ccms_oem_dbf" {
  availability_zone = "eu-west-2a"
  iops              = 3000
  size              = 200
  type              = "io2"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap(
    { "Name" = "${local.application_name}-db-mnt-oem-dbf" }
  ), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_ccms_oem_dbf" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_ccms_oem_dbf.id
  device_name = "/dev/sde"
}

resource "aws_ebs_volume" "oem_db_volume_ccms_oem_redo" {
  availability_zone = "eu-west-2a"
  iops              = 3000
  size              = 20
  type              = "io2"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap(
    { "Name" = "${local.application_name}-db-mnt-oem-redo" }
  ), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_ccms_oem_redo" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_ccms_oem_redo.id
  device_name = "/dev/sde"
}

resource "aws_ebs_volume" "oem_db_volume_ccms_oem_archive" {
  availability_zone = "eu-west-2a"
  iops              = 3000
  size              = 200
  type              = "io2"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap(
    { "Name" = "${local.application_name}-db-mnt-oem-archive" }
  ), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_ccms_oem_archive" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_ccms_oem_archive.id
  device_name = "/dev/sde"
}

resource "aws_security_group" "oem_db_security_group" {
  name_prefix = "${local.application_name}-db-server-sg"
  description = "controls access to the ebs app server"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 1159
    to_port     = 1159
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 1521
    to_port     = 1521
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 1830
    to_port     = 1849
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 3872
    to_port     = 3872
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 4889
    to_port     = 4889
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 7101
    to_port     = 7101
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 7799
    to_port     = 7799
    cidr_blocks = [data.aws_vpc.shared.cidr_block]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = local.tags
}
