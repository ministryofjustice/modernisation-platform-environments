resource "aws_instance" "ec2_ftp" {
  count                       = local.is-test ? 1 : 0
  instance_type               = local.application_data.accounts[local.environment].ec2_instance_type_ftp
  ami                         = local.application_data.accounts[local.environment].ftp_ami_id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_ftp[count.index].id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

  # Due to a bug in terraform wanting to rebuild the ec2 if more than 1 ebs block is attached, we need the lifecycle clause below.
  lifecycle {
    ignore_changes = [
      ebs_block_device,
      root_block_device,
      user_data,
      user_data_replace_on_change
    ]
  }
  user_data_replace_on_change = false
  user_data = base64encode(templatefile("./templates/ec2_user_data_ftp.sh", {
    environment               = "${local.environment}"
    lz_aws_account_id_env     = "${local.application_data.accounts[local.environment].lz_aws_account_id_env}"
    lz_ftp_bucket_environment = "${local.application_data.accounts[local.environment].lz_ftp_bucket_environment}"
    hostname                  = "ftp"
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    iops        = 3000
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    tags = merge(local.tags,
      { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ftp, "root")) },
      { device-name = "/dev/sda1" }
    )
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_type = "gp3"
    volume_size = 20
    //    iops = 12000
    encrypted  = true
    kms_key_id = data.aws_kms_key.ebs_shared.key_id
    tags = merge(local.tags,
      { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ftp, "ftp")) },
      { device-name = "/dev/sda1" }
    )
  }

  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-FTP", local.application_name, local.environment)) },
    { instance-role = local.application_data.accounts[local.environment].instance_role_ftp },
    { backup = "true" }
  )

  depends_on = [aws_security_group.ec2_sg_ftp]
}

module "cw-ftp-ec2" {
  count  = local.is-test ? 1 : 0
  source = "./modules/cw-ec2"

  short_env    = local.application_data.accounts[local.environment].short_env
  name         = "ec2-ftp"
  topic        = aws_sns_topic.cw_alerts.arn
  instanceId   = aws_instance.ec2_ftp[count.index].id
  imageId      = local.application_data.accounts[local.environment].ftp_ami_id
  instanceType = local.application_data.accounts[local.environment].ec2_instance_type_ftp
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
