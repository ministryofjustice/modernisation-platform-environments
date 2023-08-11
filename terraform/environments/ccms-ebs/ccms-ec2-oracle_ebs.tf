resource "aws_instance" "ec2_oracle_ebs" {
  instance_type = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebsdb
  #ami                         = data.aws_ami.oracle_db.id
  ami                         = local.environment == "development" ? local.application_data.accounts[local.environment].restored_db_image : data.aws_ami.oracle_db.id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_ebsdb.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

  cpu_core_count       = local.application_data.accounts[local.environment].ec2_oracle_instance_cores_ebsdb
  cpu_threads_per_core = local.application_data.accounts[local.environment].ec2_oracle_instance_threads_ebsdb

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below.
  #lifecycle {
  #  ignore_changes = [ebs_block_device]
  #}
  lifecycle {
    ignore_changes = [
      cpu_core_count,
      ebs_block_device,
      ebs_optimized,
      user_data,
      user_data_replace_on_change
    ]
  }
  user_data_replace_on_change = false
  user_data = base64encode(templatefile("./templates/ec2_user_data_ebs.sh", {
    environment = "${local.environment}"
    hostname    = "ebs"
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  /*
  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
    tags = merge(local.tags,
      { Name = "root-block" }
    )
  }
  ebs_block_device {
    device_name = "/dev/sdc"
    volume_type = "gp3"
    volume_size = local.application_data.accounts[local.environment].ebs_size_ebsdb_temp
    encrypted   = true
    tags = merge(local.tags,
      { Name = "temp" }
    )
  }
  */

  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-ebsdb", local.application_name, local.environment)) },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling },
    { backup = "true" }
  )
  depends_on = [aws_security_group.ec2_sg_ebsdb]
}

resource "aws_ebs_volume" "export_home" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_exhome
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "export/home" }
  )
}

resource "aws_volume_attachment" "export_home_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.export_home.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "u01" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_u01
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "u01" }
  )
}

resource "aws_volume_attachment" "u01_att" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.u01.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "arch" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_arch
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "arch" }
  )
}

resource "aws_volume_attachment" "arch_att" {
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.arch.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "dbf" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_dbf
  type              = "io2"
  iops              = local.application_data.accounts[local.environment].ebs_default_iops
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "dbf" }
  )
}

resource "aws_volume_attachment" "dbf_att" {
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.dbf.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "redoA" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_redoA
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "redoA" }
  )
}

resource "aws_volume_attachment" "redoA_att" {
  device_name = "/dev/sdl"
  volume_id   = aws_ebs_volume.redoA.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "techst" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_techst
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "techst" }
  )
}

resource "aws_volume_attachment" "techst_att" {
  device_name = "/dev/sdm"
  volume_id   = aws_ebs_volume.techst.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "backup" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_backup
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "backup" }
  )
}

resource "aws_volume_attachment" "backup_att" {
  device_name = "/dev/sdn"
  volume_id   = aws_ebs_volume.backup.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "redoB" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_redoB
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "redoB" }
  )
}

resource "aws_volume_attachment" "redoB_att" {
  depends_on = [
    aws_ebs_volume.redoB
  ]
  device_name = "/dev/sdo"
  volume_id   = aws_ebs_volume.redoB.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}

resource "aws_ebs_volume" "diag" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_diag
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "diag" }
  )
}

resource "aws_volume_attachment" "diag_att" {
  depends_on = [
    aws_ebs_volume.diag
  ]
  device_name = "/dev/sdp"
  volume_id   = aws_ebs_volume.diag.id
  instance_id = aws_instance.ec2_oracle_ebs.id
}
/*
####  This mount was required for golive incident
####  Just commenting out, rather than remove - just in case

resource "aws_ebs_volume" "dbf2" {
  count = local.is-production ? 1 : 0
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsdb_dbf2
  type              = "io2"
  iops              = local.application_data.accounts[local.environment].ebs_default_dbf2_iops
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "dbf2" }
  )
}

resource "aws_volume_attachment" "dbf2_att" {
  count = local.is-production ? 1 : 0
  device_name = "/dev/sdo"
  volume_id   = aws_ebs_volume.dbf2[0].id
  instance_id = aws_instance.ec2_oracle_ebs.id
}
*/

module "cw-ebs-ec2" {
  source = "./modules/cw-ec2"

  short_env    = local.application_data.accounts[local.environment].short_env
  name         = "ec2-ebs"
  topic        = aws_sns_topic.cw_alerts.arn
  instanceId   = aws_instance.ec2_oracle_ebs.id
  imageId      = local.environment == "development" ? local.application_data.accounts[local.environment].restored_db_image : data.aws_ami.oracle_db.id
  instanceType = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebsdb
  fileSystem   = "xfs"       # Linux root filesystem
  rootDevice   = "nvme0n1p1" # This is used by default for root on all the ec2 images

  cpu_eval_periods = local.application_data.cloudwatch_ec2.cpu.eval_periods
  cpu_datapoints   = local.application_data.cloudwatch_ec2.cpu.eval_periods
  cpu_period       = local.application_data.cloudwatch_ec2.cpu.period
  cpu_threshold    = local.application_data.cloudwatch_ec2.cpu.threshold

  mem_eval_periods = local.application_data.cloudwatch_ec2.mem.eval_periods
  mem_datapoints   = local.application_data.cloudwatch_ec2.mem.eval_periods
  mem_period       = local.application_data.cloudwatch_ec2.mem.period
  mem_threshold    = local.application_data.cloudwatch_ec2.mem.threshold

  disk_eval_periods = local.application_data.cloudwatch_ec2.disk.eval_periods
  disk_datapoints   = local.application_data.cloudwatch_ec2.disk.eval_periods
  disk_period       = local.application_data.cloudwatch_ec2.disk.period
  disk_threshold    = local.application_data.cloudwatch_ec2.disk.threshold

  insthc_eval_periods = local.application_data.cloudwatch_ec2.insthc.eval_periods
  insthc_period       = local.application_data.cloudwatch_ec2.insthc.period
  insthc_threshold    = local.application_data.cloudwatch_ec2.insthc.threshold

  syshc_eval_periods = local.application_data.cloudwatch_ec2.syshc.eval_periods
  syshc_period       = local.application_data.cloudwatch_ec2.syshc.period
  syshc_threshold    = local.application_data.cloudwatch_ec2.syshc.threshold
}

# Disk Free Alarm for EBSDB /dbf mount
resource "aws_cloudwatch_metric_alarm" "disk_free_dbf" {
  alarm_name                = "${local.application_data.accounts[local.environment].short_env}-EBSDB-disk_free_DBF"
  alarm_description         = "This metric monitors the amount of free disk space on dbf mount. If the amount of free disk space on root falls below 20% for 2 minutes, the alarm will trigger"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  statistic                 = "Average"
  insufficient_data_actions = []

  evaluation_periods  = local.application_data.cloudwatch_ec2.disk.eval_periods
  datapoints_to_alarm = local.application_data.cloudwatch_ec2.disk.eval_periods
  period              = local.application_data.cloudwatch_ec2.disk.period
  threshold           = local.application_data.cloudwatch_ec2.disk.threshold_dbf
  alarm_actions       = [aws_sns_topic.cw_alerts.arn]

  dimensions = {
    ImageId      = aws_instance.ec2_oracle_ebs.ami
    path         = local.application_data.accounts[local.environment].dbf_path
    InstanceType = aws_instance.ec2_oracle_ebs.instance_type
    InstanceId   = aws_instance.ec2_oracle_ebs.id
    fstype       = "ext4"
    device       = local.application_data.accounts[local.environment].dbf_device
  }
}
