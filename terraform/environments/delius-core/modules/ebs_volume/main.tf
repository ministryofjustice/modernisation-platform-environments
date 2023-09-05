resource "aws_ebs_volume" "this" {
  availability_zone = var.availability_zone
  type              = var.type
  iops              = var.iops
  throughput        = var.throughput
  size              = var.size
#   encrypted         = true
  kms_key_id        = var.kms_key_id
  tags              = var.tags
}

resource "aws_volume_attachment" "this" {
  device_name  = var.device_name
  volume_id    = aws_ebs_volume.this.id
  instance_id  = var.instance_id
  skip_destroy = true
} 