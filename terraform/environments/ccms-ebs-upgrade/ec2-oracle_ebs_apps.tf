resource "aws_instance" "ec2_ebsapps" {
  count                  = local.application_data.accounts[local.environment].ebsapps_no_instances
  instance_type          = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebsapps
  ami                    = local.application_data.accounts[local.environment]["ebsapps_ami_id-${count.index + 1}"]
  key_name               = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg_ebsapps.id]
  subnet_id              = local.private_subnets[count.index]
  #subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = local.application_data.accounts[local.environment].ebs_optimized
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

  cpu_options {
    core_count       = local.application_data.accounts[local.environment].ec2_oracle_instance_cores_ebsapps
    threads_per_core = local.application_data.accounts[local.environment].ec2_oracle_instance_threads_ebsapps
  }

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below.
  lifecycle {
    ignore_changes = [
      ebs_block_device,
      user_data,
      user_data_replace_on_change
    ]
  }
  user_data_replace_on_change = false
  user_data = base64encode(templatefile("./templates/ec2_user_data_ebs_apps.sh", {
    hostname = "ebs-apps"
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # AMI ebs mappings from /dev/sd[a-d]
  # root
  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    encrypted   = true
    tags = merge(local.tags,
      { Name = lower(format("%s-%s-%s", local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "root")) },
      { device-name = "/dev/sda1" }
    )
  }

  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-ebsapps-%s", local.application_name, local.environment, count.index + 1)) },
    { instance-role = local.application_data.accounts[local.environment].instance_role_ebsapps },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling-ebsapps },
    { backup = "true" }
  )
  depends_on = [aws_security_group.ec2_sg_ebsapps]
}

resource "aws_ebs_volume" "swap" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = 20
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "swap")) },
    { device-name = "/dev/sdb" }
  )
}

resource "aws_volume_attachment" "swap_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.swap]
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.swap[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

resource "aws_ebs_volume" "temp" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = 100
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "temp")) },
    { device-name = "/dev/sdc" }
  )
}

resource "aws_volume_attachment" "temp_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.temp]
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.temp[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

resource "aws_ebs_volume" "home" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = 100
  type              = "gp3"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "home")) },
    { device-name = "/dev/sdd" }
  )
}

resource "aws_volume_attachment" "home_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.home]
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.home[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

resource "aws_ebs_volume" "apps_export_home" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = local.application_data.accounts[local.environment].ebsapps_exhome_size
  type              = "io2"
  iops              = local.application_data.accounts[local.environment].ebsapps_default_iops
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "export-home")) },
    { device-name = "/dev/sdh" }
  )
}

resource "aws_volume_attachment" "apps_export_home_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.apps_export_home]
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.apps_export_home[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

resource "aws_ebs_volume" "apps_u01" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = local.application_data.accounts[local.environment].ebsapps_u01_size
  type              = "io2"
  iops              = local.application_data.accounts[local.environment].ebsapps_default_iops
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "u01")) },
    { device-name = "/dev/sdi" }
  )
}

resource "aws_volume_attachment" "apps_u01_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.apps_u01]
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.apps_u01[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

resource "aws_ebs_volume" "apps_u03" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = local.application_data.accounts[local.environment].ebsapps_u03_size
  type              = "io2"
  iops              = local.application_data.accounts[local.environment].ebsapps_default_iops
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "u03")) },
    { device-name = "/dev/sdj" }
  )
}

resource "aws_volume_attachment" "apps_u03_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.apps_u03]
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.apps_u03[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

resource "aws_ebs_volume" "stage" {
  count = local.application_data.accounts[local.environment].ebsapps_no_instances
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = aws_instance.ec2_ebsapps[count.index].availability_zone
  size              = local.application_data.accounts[local.environment].ebsapps_stage_size
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-%s", local.application_data.accounts[local.environment].instance_role_ebsapps, count.index + 1, "stage")) },
    { device-name = "/dev/sdk" }
  )
}

resource "aws_volume_attachment" "stage_att" {
  count       = local.application_data.accounts[local.environment].ebsapps_no_instances
  depends_on  = [aws_ebs_volume.stage]
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.stage[count.index].id
  instance_id = aws_instance.ec2_ebsapps[count.index].id
}

module "cw-ebsapps-ec2" {
  source = "./modules/cw-ec2"
  count  = local.application_data.accounts[local.environment].ebsapps_no_instances

  short_env    = local.application_data.accounts[local.environment].short_env
  name         = "ec2-ebsapps-${count.index + 1}"
  topic        = aws_sns_topic.cw_alerts.arn
  instanceId   = aws_instance.ec2_ebsapps[count.index].id
  imageId      = local.application_data.accounts[local.environment]["ebsapps_ami_id-${count.index + 1}"]
  instanceType = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebsapps
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
