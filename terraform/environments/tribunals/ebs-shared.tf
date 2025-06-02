resource "aws_ebs_volume" "tribunals-ebs" {
  #checkov:skip=CKV_AWS_189:"Default AWS encryption is sufficient for this use case"
  availability_zone = "eu-west-2a"
  type              = "gp2"
  size              = 10
  encrypted         = true

  tags = merge(
    local.tags,
    {
      Name = "tribunals-all-storage"
    }
  )
}

resource "aws_ebs_volume" "tribunals-backup-ebs" {
  #checkov:skip=CKV_AWS_189:"Default AWS encryption is sufficient for this use case"
  availability_zone = "eu-west-2b"
  type              = "gp2"
  size              = 10
  encrypted         = true

  tags = merge(
    local.tags,
    {
      Name = "tribunals-backup-storage"
    }
  )
}
