resource "aws_ebs_volume" "tribunals-ebs" {
  depends_on        = [aws_instance.cjip-server]
  availability_zone = "${local.region}a"
  type              = "gp2"

  snapshot_id = local.application_data.accounts[local.environment].suprig05-disk-1-snapshot

  tags = merge(
    local.tags,
    {
      Name = "tribunals-all"
    }
  )
}

resource "aws_volume_attachment" "tribunals-ebs" {
  depends_on   = [aws_instance.cjip-server]
  device_name  = "xvdk"
  force_detach = true
  volume_id    = aws_ebs_volume.tribunals-ebs.id
  instance_id  = aws_instance.cjip-server.id
}