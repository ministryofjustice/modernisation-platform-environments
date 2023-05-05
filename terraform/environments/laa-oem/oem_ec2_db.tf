resource "aws_key_pair" "key_pair_db" {
  key_name   = lower(format("oem-ec2-key-db-%s", local.environment))
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJB1m1MUEKtff5y6RLEAm2f1v9g7TmqAyrk4svTBeqpK"

  tags = merge(tomap({
    "Name" = lower(format("ec2-%s-%s-db", local.application_name, local.environment))
  }), local.tags)
}

resource "aws_instance" "oem_db" {
  ami                         = data.aws_ami.ec2_laa_oem_development_db.id
  associate_public_ip_address = false
  availability_zone           = local.application_data.accounts[local.environment].ec2_zone
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_oem_base.name
  instance_type               = local.application_data.accounts[local.environment].ec2_oem_instance_type_db
  key_name                    = aws_key_pair.key_pair_db.id
  monitoring                  = true
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  user_data_replace_on_change = true
  user_data = base64encode(templatefile("./templates/oem-user-data-db.sh", {
    efs_fqdn = aws_efs_file_system.oem_db_efs.dns_name
    env_fqdn = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
    hostname = "laa-oem-db"
  }))
  vpc_security_group_ids = [aws_security_group.oem_db_security_group.id]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = data.aws_kms_key.ebs_shared.arn
    iops                  = 3100
    volume_size           = 12
    volume_type           = "gp3"
  }

  volume_tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-root",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sda1",
    "volume-mount-path"    = "/",
    "volume-backup"        = true
  }), local.tags)

  tags = merge(tomap({
    "Name"     = lower(format("ec2-%s-%s-db", local.application_name, local.environment)),
    "hostname" = "${local.application_name}-db",
    "env-fqdn" = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
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
  kms_key_id        = data.aws_kms_key.ebs_shared.arn
  size              = 32
  type              = "gp3"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-swap",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sdb",
    "volume-mount-path"    = "swap",
    "volume-backup"        = true
  }), local.tags)
}

resource "aws_volume_attachment" "oem_db_volume_swap" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_swap.id
  device_name = "/dev/sdb"
}

resource "aws_ebs_volume" "oem_db_volume_opt_oem_app" {
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  kms_key_id        = data.aws_kms_key.ebs_shared.arn
  size              = 50
  snapshot_id       = data.aws_ebs_snapshot.oem_db_volume_opt_oem_app.id
  type              = "gp3"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-opt-oem-app",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sdc",
    "volume-mount-path"    = "/opt/oem/app",
    "volume-backup"        = true
  }), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_opt_oem_app" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_opt_oem_app.id
  device_name = "/dev/sdc"
}

resource "aws_ebs_volume" "oem_db_volume_opt_oem_inst" {
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  kms_key_id        = data.aws_kms_key.ebs_shared.arn
  size              = 50
  snapshot_id       = data.aws_ebs_snapshot.oem_db_volume_opt_oem_inst.id
  type              = "gp3"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-opt-oem-inst",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sdd",
    "volume-mount-path"    = "/opt/oem/inst",
    "volume-backup"        = true
  }), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_opt_oem_inst" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_opt_oem_inst.id
  device_name = "/dev/sdd"
}

resource "aws_ebs_volume" "oem_db_volume_opt_oem_dbf" {
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  kms_key_id        = data.aws_kms_key.ebs_shared.arn
  size              = 200
  snapshot_id       = data.aws_ebs_snapshot.oem_db_volume_opt_oem_dbf.id
  type              = "io2"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-opt-oem-dbf",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sde",
    "volume-mount-path"    = "/opt/oem/dbf",
    "volume-backup"        = true
  }), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_opt_oem_dbf" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_opt_oem_dbf.id
  device_name = "/dev/sde"
}

resource "aws_ebs_volume" "oem_db_volume_opt_oem_redo" {
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  kms_key_id        = data.aws_kms_key.ebs_shared.arn
  size              = 20
  snapshot_id       = data.aws_ebs_snapshot.oem_db_volume_opt_oem_redo.id
  type              = "io2"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-opt-oem-redo",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sdf",
    "volume-mount-path"    = "/opt/oem/redo",
    "volume-backup"        = true
  }), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_opt_oem_redo" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_opt_oem_redo.id
  device_name = "/dev/sdf"
}

resource "aws_ebs_volume" "oem_db_volume_opt_oem_arch" {
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  kms_key_id        = data.aws_kms_key.ebs_shared.arn
  size              = 200
  snapshot_id       = data.aws_ebs_snapshot.oem_db_volume_opt_oem_arch.id
  type              = "io2"
  depends_on        = [resource.aws_instance.oem_db]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-db-opt-oem-arch",
    "volume-attach-host"   = "db",
    "volume-attach-device" = "/dev/sdg",
    "volume-mount-path"    = "/opt/oem/arch",
    "volume-backup"        = true
  }), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_db_volume_opt_oem_arch" {
  instance_id = aws_instance.oem_db.id
  volume_id   = aws_ebs_volume.oem_db_volume_opt_oem_arch.id
  device_name = "/dev/sdg"
}
