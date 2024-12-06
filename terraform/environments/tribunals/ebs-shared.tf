resource "aws_ebs_volume" "tribunals-ebs" {
  availability_zone = "eu-west-2a"
  type              = "gp2"
  size              = 10

  tags = merge(
    local.tags,
    {
      Name = "tribunals-all-storage"
    }
  )
}

resource "aws_ebs_volume" "tribunals-ebs-2" {
  availability_zone = "eu-west-2b"
  type             = "gp2"
  size             = 10

  tags = merge(
    local.tags,
    {
      Name = "tribunals-all-storage-b"
    }
  )
}