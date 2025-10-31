#module "ebs_volumes" {
#  source = "../ebs_volume"
#  for_each = {
#    for k, v in var.ebs_volumes.ebs_non_root_volumes : k => v if v.no_device == false
#  }
#  availability_zone = aws_instance.db_ec2.availability_zone
#  instance_id       = aws_instance.db_ec2.id
#  device_name       = each.key
#  size              = each.value.volume_size
#  iops              = var.ebs_volumes.iops
#  throughput        = var.ebs_volumes.throughput
#  tags              = var.tags
#  kms_key_id        = var.ebs_volumes.kms_key_id
#  depends_on = [
#    aws_instance.db_ec2
#  ]
#}
