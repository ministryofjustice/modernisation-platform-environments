resource "aws_key_pair" "key_pair_app" {
  key_name   = lower(format("%s-%s-key", local.application_name, local.environment))
  public_key = local.pubkey[local.environment]
  tags = merge(tomap({
    "Name" = lower(format("ec2-%s-%s-app", local.application_name, local.environment))
  }), local.tags)
}



resource "aws_instance" "tariff_app" {
  ami                         = data.aws_ami.shared_ami.id
  associate_public_ip_address = false
  ebs_optimized               = true
  ##iam_instance_profile        = aws_iam_instance_profile.tariff_ec2_instance_profile.name
  instance_type               = "m5.2xlarge"
  key_name                    = aws_key_pair.key_pair_app.key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  user_data_replace_on_change = true
  vpc_security_group_ids = [aws_security_group.tariff_app_security_group.id]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 20
  }

  volume_tags = merge(tomap({
    "Name"                 = "${local.application_name}-app-root",
    "volume-attach-host"   = "app",
    "volume-attach-device" = "/dev/sda1",
    "volume-mount-path"    = "/"
  }), local.tags)

  tags = merge(tomap({
    "Name"     = lower(format("ec2-%s-%s-app", local.application_name, local.environment)),
    "hostname" = "${local.application_name}-app",
  }), local.tags)

  lifecycle {
    ignore_changes = [ami]
  }
}
resource "aws_ebs_volume" "u01" {
  availability_zone = aws_instance.tariff_app.availability_zone
  size              = 100
  encrypted         = true
  type              = "gp3"
  tags = merge(tomap({
    "Name"                 = "${local.application_name}-app-u01",
    "volume-attach-host"   = "app",
    "volume-attach-device" = "xvde"
  }), local.tags)
  
  lifecycle {
    ignore_changes = [
      snapshot_id,
      kms_key_id
    ]
  }
}

#attach volume to ec2 instance
resource "aws_volume_attachment" "disk-attach-u01" {
  device_name  = "xvde"
  volume_id    = aws_ebs_volume.u01.id
  instance_id  = aws_instance.tariff_app.id
  force_detach = true
}

resource "aws_ebs_volume" "u02" {
  availability_zone = aws_instance.tariff_app.availability_zone
  size              = 100
  encrypted         = true
  type              = "gp3"
  tags = merge(tomap({
    "Name"                 = "${local.application_name}-app-u02",
    "volume-attach-host"   = "app",
    "volume-attach-device" = "xvdf"
  }), local.tags)
  
  lifecycle {
    ignore_changes = [
      snapshot_id,
      kms_key_id
    ]
  }
}

#attach volume to ec2 instance
resource "aws_volume_attachment" "disk-attach-u02" {
  device_name  = "xvdf"
  volume_id    = aws_ebs_volume.u02.id
  instance_id  = aws_instance.tariff_app.id
  force_detach = true
}

resource "aws_ebs_volume" "u03" {
  availability_zone = aws_instance.tariff_app.availability_zone
  size              = 100
  encrypted         = true
  type              = "gp3"
  tags = merge(tomap({
    "Name"                 = "${local.application_name}-app-u03",
    "volume-attach-host"   = "app",
    "volume-attach-device" = "xvdg"
  }), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id,
      kms_key_id
    ]
  }
  }

#attach volume to ec2 instance
resource "aws_volume_attachment" "disk-attach-u03" {
  device_name  = "xvdg"
  volume_id    = aws_ebs_volume.u03.id
  instance_id  = aws_instance.tariff_app.id
  force_detach = true
}

resource "aws_ebs_volume" "swap" {
  availability_zone = aws_instance.tariff_app.availability_zone
  size              = 16
  encrypted         = true
  type              = "gp3"
  tags = merge(tomap({
    "Name"                 = "${local.application_name}-app-swap",
    "volume-attach-host"   = "app",
    "volume-attach-device" = "xvdh"
  }), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id,
      kms_key_id
    ]
  }
}


#attach volume to ec2 instance
resource "aws_volume_attachment" "disk-attach-swap" {
  device_name  = "xvdh"
  volume_id    = aws_ebs_volume.swap.id
  instance_id  = aws_instance.tariff_app.id
  force_detach = true
}

resource "aws_ebs_volume" "export" {
  availability_zone = aws_instance.tariff_app.availability_zone
  size              =  30
  encrypted         = true
  type              = "gp3"
  tags = merge(tomap({
    "Name"                 = "${local.application_name}-app-export",
    "volume-attach-host"   = "app",
    "volume-attach-device" = "xvdi"
  }), local.tags)

  lifecycle {
    ignore_changes = [
      snapshot_id,
      kms_key_id
    ]
  }
}

#attach volume to ec2 instance
resource "aws_volume_attachment" "disk-attach-export" {
  device_name  = "xvdi"
  volume_id    = aws_ebs_volume.export.id
  instance_id  = aws_instance.tariff_app.id
  force_detach = true
}


