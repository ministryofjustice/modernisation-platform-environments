resource "aws_instance" "db_ec2" {

  #checkov:skip=CKV2_AWS_41:"IAM role is not implemented for this example EC2. SSH/AWS keys are not used either."
  instance_type               = var.db_type
  ami                         = var.db_ami
  vpc_security_group_ids      = [aws_security_group.db_ec2_instance_sg.id, aws_security_group.delius_db_security_group.id]
  subnet_id                   = var.subnet_id
  iam_instance_profile        = aws_iam_instance_profile.db_ec2_instanceprofile.name
  associate_public_ip_address = false
  monitoring                  = var.monitoring
  ebs_optimized               = true
  key_name                    = aws_key_pair.environment_ec2_user_key_pair.key_name
  user_data_base64            = base64encode(var.user_data)

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
    { Name = lower(format("%s-delius-db-%s", var.env_name, var.db_count_index)) },
    { server-type = "delius_core_db" },
    { database = "delius_${var.db_name}" }
  )
}