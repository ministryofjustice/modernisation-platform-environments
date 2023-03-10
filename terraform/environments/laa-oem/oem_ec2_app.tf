resource "aws_instance" "oem_app" {
  ami                         = local.ami_app
  associate_public_ip_address = false
  availability_zone           = local.application_data.accounts[local.environment].ec2_zone
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_oem_base.name
  instance_type               = local.application_data.accounts[local.environment].ec2_oem_instance_type_app
  key_name                    = local.application_data.accounts[local.environment].key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.data_subnets_b.id
  user_data_replace_on_change = true
  user_data = base64encode(templatefile("./templates/oem-user-data-app.sh", {
    efs_id      = aws_efs_file_system.oem-app-efs.id
    env_in_fqdn = local.application_data.accounts[local.environment].env_in_fqdn
    hostname    = "laa-oem-app"
  }))
  vpc_security_group_ids = [aws_security_group.oem_app_security_group_1.id, aws_security_group.oem_app_security_group_2.id]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    iops                  = 3100
    volume_size           = 12
    volume_type           = "gp3"
  }

  volume_tags = merge(tomap({
    "Name"                 = "${local.application_name}-app-root",
    "volume-attach-host"   = "app",
    "volume-attach-device" = "/dev/sda1",
    "volume-mount-path"    = "/"
  }), local.tags)

  tags = merge(tomap({
    "Name"     = lower(format("ec2-%s-%s-app", local.application_name, local.environment)),
    "hostname" = "${local.application_name}-app"
  }), local.tags)

  lifecycle {
    ignore_changes = [
      volume_tags,
      user_data
    ]
  }
}

resource "aws_ebs_volume" "oem_app_volume_swap" {
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  size              = 32
  type              = "gp3"
  depends_on        = [resource.aws_instance.oem_app]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-app-swap",
    "volume-attach-host"   = "app",
    "volume-attach-device" = "/dev/sdb",
    "volume-mount-path"    = "swap"
  }), local.tags)
}

resource "aws_volume_attachment" "oem_app_volume_swap" {
  instance_id = aws_instance.oem_app.id
  volume_id   = aws_ebs_volume.oem_app_volume_swap.id
  device_name = "/dev/sdb"
}

resource "aws_ebs_volume" "oem_app_volume_ccms_oem_app" {
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  size              = 50
  snapshot_id       = local.vol_snap_app_app
  type              = "gp3"
  depends_on        = [resource.aws_instance.oem_app]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-app-mnt-oem-app",
    "volume-attach-host"   = "app",
    "volume-attach-device" = "/dev/sdc",
    "volume-mount-path"    = "/opt/oem/app"
  }), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_app_volume_ccms_oem_app" {
  instance_id = aws_instance.oem_app.id
  volume_id   = aws_ebs_volume.oem_app_volume_ccms_oem_app.id
  device_name = "/dev/sdc"
}

resource "aws_ebs_volume" "oem_app_volume_ccms_oem_inst" {
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  encrypted         = true
  iops              = 3000
  size              = 50
  snapshot_id       = local.vol_snap_app_inst
  type              = "gp3"
  depends_on        = [resource.aws_instance.oem_app]

  tags = merge(tomap({
    "Name"                 = "${local.application_name}-app-mnt-oem-inst",
    "volume-attach-host"   = "app",
    "volume-attach-device" = "/dev/sdd",
    "volume-mount-path"    = "/opt/oem/inst"
  }), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id
    ]
  }
}

resource "aws_volume_attachment" "oem_app_volume_ccms_oem_inst" {
  instance_id = aws_instance.oem_app.id
  volume_id   = aws_ebs_volume.oem_app_volume_ccms_oem_inst.id
  device_name = "/dev/sdd"
}
