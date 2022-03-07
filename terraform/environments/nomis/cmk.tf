resource "aws_kms_key" "nomis-cmk" {
  description             = "Nomis Managed Key for AMI Sharing"
  deletion_window_in_days = 10
  policy                  = file("${path.module}files/policy.json")
}

resource "aws_kms_alias" "nomis-key" {
  name          = "alias/nomis-image-builder"
  target_key_id = aws_kms_key.nomis-cmk.key_id
}

