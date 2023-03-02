resource "aws_instance" "oem_app" {
  ami                         = "ami-0c6f19670d053404e"
  associate_public_ip_address = false
  availability_zone           = local.application_data.accounts[local.environment].ec2_zone
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name
  instance_type               = local.application_data.accounts[local.environment].ec2_oem_instance_type_app
  key_name                    = local.application_data.accounts[local.environment].key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.data_subnets_b.id
  user_data_replace_on_change = true
  user_data = base64encode(templatefile("./templates/oem-user-data-app.sh", {
    efs_id   = aws_efs_file_system.oem-app-efs.id
    hostname = "ccms-oem-app"
  }))
  vpc_security_group_ids = [aws_security_group.oem_app_security_group_1.id, aws_security_group.oem_app_security_group_2.id]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    iops                  = 3100
    volume_size           = 12
    volume_type           = "gp3"
  }

  volume_tags = merge(tomap(
    { "Name" = "${local.application_name}-app-root" }
  ), local.tags)

  tags = merge(tomap(
    { "Name" = lower(format("ec2-%s-%s-app", local.application_name, local.environment)) }
  ), local.tags)

  lifecycle {
    ignore_changes = [
      volume_tags,
      user_data
    ]
  }
}

resource "aws_ebs_volume" "oem_app_volume_swap" {
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  depends_on        = [resource.aws_instance.oem_app]
  encrypted         = true
  size              = 32
  type              = "gp3"

  tags = merge(tomap(
    { "Name" = "${local.application_name}-app-swap" }
  ), local.tags)
}

resource "aws_volume_attachment" "oem_app_volume_swap" {
  instance_id = aws_instance.oem_app.id
  volume_id   = aws_ebs_volume.oem_app_volume_swap.id
  device_name = "/dev/sdb"
}

resource "aws_ebs_volume" "oem_app_volume_ccms_oem_app" {
  availability_zone = local.application_data.accounts[local.environment].ec2_zone
  depends_on        = [resource.aws_instance.oem_app]
  encrypted         = true
  size              = 50
  type              = "gp3"

  tags = merge(tomap(
    { "Name" = "${local.application_name}-app-mnt-oem-app" }
  ), local.tags)

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
  depends_on        = [resource.aws_instance.oem_app]
  encrypted         = true
  size              = 50
  type              = "gp3"

  tags = merge(tomap(
    { "Name" = "${local.application_name}-app-mnt-oem-inst" }
  ), local.tags)

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
