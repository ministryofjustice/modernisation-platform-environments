resource "aws_ebs_volume" "this" {
  availability_zone = var.availability_zone
  type              = var.type
  iops              = var.iops
  throughput        = var.throughput
  size              = var.size
  encrypted         = true
  kms_key_id        = var.kms_key_id
  tags = merge(var.tags,
    var.enable_platform_backups != null ? { "backup" = var.enable_platform_backups ? "true" : "false" } : {}
  )
  lifecycle {
    ignore_changes = [availability_zone]
  }
}

resource "aws_volume_attachment" "this" {
  device_name = var.device_name
  volume_id   = aws_ebs_volume.this.id
  instance_id = var.instance_id
}
