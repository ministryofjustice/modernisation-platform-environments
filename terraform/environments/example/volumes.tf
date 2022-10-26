# Volumes built for use by EC2.
resource "aws_kms_key" "ec2" {
  description         = "Encryption key for EBS"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.ebs-kms.json

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ebs-kms"
    }
  )
}

resource "aws_ebs_volume" "ebs_volume" {
  availability_zone = "${local.application_data.accounts[local.environment].region}a"
  type              = "gp3"
  size              = 50
  throughput        = 200
  encrypted         = true
  kms_key_id        = aws_kms_key.ec2.arn
  tags = {
    Name = "ebs-data-volume"
  }

  depends_on = [aws_instance.develop, aws_kms_key.ec2]
}
# Attach to the EC2
resource "aws_volume_attachment" "mountvolumetoec2" {
  device_name = "/dev/sdb"
  instance_id = aws_instance.develop.id
  volume_id   = aws_ebs_volume.ebs_volume.id
}
