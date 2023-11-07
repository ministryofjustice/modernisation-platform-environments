resource "aws_instance" "ec2_oracle_conc" {
  instance_type = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebsconc
  ami                         = local.application_data.accounts[local.environment].ebsconc_ami_id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_ebsconc.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

  cpu_core_count       = local.application_data.accounts[local.environment].ec2_oracle_instance_cores_ebsconc
  cpu_threads_per_core = local.application_data.accounts[local.environment].ec2_oracle_instance_threads_ebsconc

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

  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-ebsconc", local.application_name, local.environment)) },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling },
    { backup = "true" },
    { OracleDbLTS-ManagedInstance = "true" }
  )
  depends_on = [aws_security_group.ec2_sg_ebsconc]
}

resource "aws_ebs_volume" "conc_export_home" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsconc_exhome
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "conc export/home" }
  )
}

resource "aws_volume_attachment" "conc_export_home_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.conc_export_home.id
  instance_id = aws_instance.ec2_oracle_conc.id
}

resource "aws_ebs_volume" "conc_u01" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsconc_u01
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "conc u01" }
  )
}

resource "aws_volume_attachment" "conc_u01_att" {
  device_name = "/dev/sdi"
  volume_id   = aws_ebs_volume.conc_u01.id
  instance_id = aws_instance.ec2_oracle_conc.id
}

resource "aws_ebs_volume" "conc_u03" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsconc_u03
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "conc u03" }
  )
}

resource "aws_volume_attachment" "conc_u03_att" {
  device_name = "/dev/sdj"
  volume_id   = aws_ebs_volume.conc_u01.id
  instance_id = aws_instance.ec2_oracle_conc.id
}

resource "aws_ebs_volume" "conc_home" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsconc_home
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "conc home" }
  )
}

resource "aws_volume_attachment" "conc_home_att" {
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.conc_home.id
  instance_id = aws_instance.ec2_oracle_conc.id
}

resource "aws_ebs_volume" "conc_stage" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsconc_stage
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "conc stage" }
  )
}

resource "aws_volume_attachment" "conc_stage_att" {
  device_name = "/dev/sdl"
  volume_id   = aws_ebs_volume.conc_stage.id
  instance_id = aws_instance.ec2_oracle_conc.id
}

resource "aws_ebs_volume" "conc_temp" {
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  availability_zone = "eu-west-2a"
  size              = local.application_data.accounts[local.environment].ebs_size_ebsconc_temp
  type              = "io2"
  iops              = 3000
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = "conc temp" }
  )
}

resource "aws_volume_attachment" "conc_temp_att" {
  device_name = "/dev/sdm"
  volume_id   = aws_ebs_volume.conc_temp.id
  instance_id = aws_instance.ec2_oracle_conc.id
}


# AppShare created for EBSDB and attached also on Conc instance

resource "aws_volume_attachment" "appshare_conc_att" {
  depends_on = [
    aws_ebs_volume.appshare
  ]
  device_name = "/dev/sdq"
  volume_id   = aws_ebs_volume.appshare.id
  instance_id = aws_instance.ec2_oracle_conc.id
}

module "cw-conc-ec2" {
  source = "./modules/cw-ec2"

  short_env    = local.application_data.accounts[local.environment].short_env
  name         = "ec2-ebs"
  topic        = aws_sns_topic.cw_alerts.arn
  instanceId   = aws_instance.ec2_oracle_ebs.id
  imageId      = local.application_data.accounts[local.environment].ebsconc_ami_id
  instanceType = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebsconc
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
