

resource "aws_instance" "db_ec2" {
  #checkov:skip=CKV2_AWS_41:"IAM role is not implemented for this example EC2. SSH/AWS keys are not used either."
  instance_type               = var.ec2_instance_type
  ami                         = data.aws_ami.oracle_db.id
  vpc_security_group_ids      = var.security_group_ids
  subnet_id                   = var.subnet_id
  iam_instance_profile        = var.instance_profile.name
  associate_public_ip_address = false
  monitoring                  = var.monitoring
  ebs_optimized               = true
  key_name                    = var.ec2_key_pair_name
  user_data_base64            = var.user_data

  metadata_options {
    http_endpoint = var.metadata_options.http_endpoint
    http_tokens   = var.metadata_options.http_tokens
  }

  root_block_device {
    volume_type = var.ebs_volumes.root_volume.volume_type
    volume_size = var.ebs_volumes.root_volume.volume_size
    iops        = var.ebs_volumes.iops
    throughput  = var.ebs_volumes.throughput
    encrypted   = true
    kms_key_id  = var.ebs_volumes.kms_key_id
    tags        = var.tags
  }

  dynamic "ephemeral_block_device" {
    for_each = { for k, v in var.ebs_volumes.ebs_non_root_volumes : k => v if v.no_device == true }
    content {
      device_name = ephemeral_block_device.key
      no_device   = true
    }
  }
  tags = merge(var.tags,
    { Name = lower(format("%s-delius-db-%s", var.env_name, local.instance_name_index)) },
    { server-type = "delius_core_db" },
    { database = local.database_tag }
  )
}
