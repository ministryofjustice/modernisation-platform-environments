resource "aws_instance" "oem_db" {
  ami                         = local.ami_db
  associate_public_ip_address = false
  availability_zone           = local.application_data.accounts[local.environment].ec2_zone
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name
  instance_type               = local.application_data.accounts[local.environment].ec2_oem_instance_type_db
  key_name                    = local.application_data.accounts[local.environment].key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.data_subnets_b.id
  user_data_replace_on_change = true
  user_data = base64encode(templatefile("./templates/oem-user-data-db.sh", {
    efs_id      = aws_efs_file_system.oem-db-efs.id
    env_in_fqdn = local.application_data.accounts[local.environment].env_in_fqdn
    hostname    = "ccms-oem-db"
  }))
  vpc_security_group_ids = [aws_security_group.oem_db_security_group.id]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    iops                  = 3100
    volume_size           = 12
    volume_type           = "gp3"
  }

  volume_tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-root",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sda1",
    "volume-mount-path"    = "/"
  }), local.tags)

  tags = merge(tomap({
    "Name" = lower(format("ec2-%s-%s-db", local.application_name, local.environment))
  }), local.tags)

  lifecycle {
    ignore_changes = [
      volume_tags,
      user_data
    ]
  }
}

resource "aws_ebs_volume" "oem_db_volume_swap" {
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  size              = 32
  type              = "gp3"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-swap",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sdb",
    "volume-mount-path"    = "swap"
  }), local.tags)
}

resource "aws_volume_attachment" "oem_db_volume_swap" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_swap.id
  device_name = "/dev/sdb"
}

resource "aws_ebs_volume" "oem_db_volume_ccms_oem_app" {
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  size              = 50
  snapshot_id       = local.vol_snap_db_app
  type              = "gp3"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-mnt-oem-app",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sdc",
    "volume-mount-path"    = "/opt/oem/app"
  }), local.tags)

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
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  size              = 50
  snapshot_id       = local.vol_snap_db_inst
  type              = "gp3"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-mnt-oem-inst",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sdd",
    "volume-mount-path"    = "/opt/oem/inst"
  }), local.tags)

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
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  size              = 200
  snapshot_id       = local.vol_snap_db_dbf
  type              = "io2"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-mnt-oem-dbf",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sde",
    "volume-mount-path"    = "/opt/oem/dbf"
  }), local.tags)

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
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  size              = 20
  snapshot_id       = local.vol_snap_db_redo
  type              = "io2"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-mnt-oem-redo",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sdf",
    "volume-mount-path"    = "/opt/oem/redo"
  }), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_ccms_oem_redo" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_ccms_oem_redo.id
  device_name = "/dev/sdf"
}

resource "aws_ebs_volume" "oem_db_volume_ccms_oem_arch" {
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  size              = 200
  snapshot_id       = local.vol_snap_db_arch
  type              = "io2"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-mnt-oem-arch",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sdg",
    "volume-mount-path"    = "/opt/oem/arch"
  }), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_ccms_oem_arch" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_ccms_oem_arch.id
  device_name = "/dev/sdg"
}