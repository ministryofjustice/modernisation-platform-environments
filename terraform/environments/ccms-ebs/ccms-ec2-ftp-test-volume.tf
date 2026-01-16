# Test volume - add as separate resource to avoid instance replacement
resource "aws_ebs_volume" "ftp_test" {
  lifecycle {
    ignore_changes = [
      kms_key_id,
      tags
    ]
  }
  availability_zone = "eu-west-2a"
  size              = 5
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ftp, "test")) },
    { device-name = "/dev/sdc" }
  )
}

resource "aws_volume_attachment" "ftp_test_att" {
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.ftp_test.id
  instance_id = aws_instance.ec2_ftp.id
}

# Second test volume
resource "aws_ebs_volume" "ftp_test2" {
  lifecycle {
    ignore_changes = [
      kms_key_id,
      tags
    ]
  }
  availability_zone = "eu-west-2a"
  size              = 20
  type              = "gp3"
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs_shared.key_id
  tags = merge(local.tags,
    { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_ftp, "test2")) },
    { device-name = "/dev/sdd" }
  )
}

resource "aws_volume_attachment" "ftp_test2_att" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.ftp_test2.id
  instance_id = aws_instance.ec2_ftp.id
}
