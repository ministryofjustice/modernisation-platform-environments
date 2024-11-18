######################################
# CIS S3FS EC2 Instance
######################################

resource "aws_instance" "cis_s3fs_instance" {
  count                       = local.create_cis_s3fs_instance ? 1 : 0
  ami                         = local.application_data.accounts[local.environment].s3fs_ami_id
  instance_type               = local.application_data.accounts[local.environment].s3fsinstancetype
  key_name                    = aws_key_pair.cis.key_name
  ebs_optimized               = true
  monitoring                  = true
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.s3fs_instance_profile.name
  vpc_security_group_ids      = [aws_security_group.ec2_instance_sg.id]
  user_data_base64            = base64encode(local.s3fs-instance-userdata)
  user_data_replace_on_change = true

  root_block_device {
    delete_on_termination = false
    encrypted             = true
    volume_size           = 10
    volume_type           = "gp2"
    tags = merge(
      { "instance-scheduling" = "skip-scheduling" },
      local.tags,
      { "Name" = "${local.application_name_short}-root" }
    )
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name_short} S3FS Server" },
    { "instance-scheduling" = "skip-scheduling" },
    { "snapshot-with-daily-7-day-retention" = "yes" }
  )
}


######################################
# CIS S3FS IAM Role
######################################

resource "aws_iam_instance_profile" "s3fs_instance_profile" {
  name = "${local.application_name_short}-s3fs-profile"
  role = aws_iam_role.cis_s3fs_role.name
}