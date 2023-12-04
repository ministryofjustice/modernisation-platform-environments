module "ebs_volumes" {
  source = "../../ebs_volume"
  for_each = {
    for k, v in var.ebs_volumes.ebs_non_root_volumes : k => v if v.no_device == false
  }
  availability_zone = aws_instance.db_ec2[each.value.index_name].availability_zone
  instance_id       = aws_instance.db_ec2[each.value.index_name].id
  device_name       = each.value.block_name
  size              = each.value.ebs_non_root_volumes.volume_size
  iops              = each.value.ebs_config.iops
  throughput        = each.value.ebs_config.throughput
  tags              = var.tags
  kms_key_id        = each.value.ebs_config.kms_key_id
  depends_on = [
    aws_instance.db_ec2
  ]
}
