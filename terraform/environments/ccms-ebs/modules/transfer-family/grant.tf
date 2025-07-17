#--S3 Grants
resource "aws_s3control_access_grants_instance" "this" {
  identity_center_arn = tolist(data.aws_ssoadmin_instances.entra.identity_store_ids)[0]
}

resource "aws_s3control_access_grants_location" "this" {
  depends_on = [aws_s3control_access_grants_instance.this]

  iam_role_arn   = aws_iam_role.s3.arn
  location_scope = "s3://${var.bucket_name}/*"
}

resource "aws_s3control_access_grant" "this" {
  permission                = "READWRITE"
  access_grants_location_id = aws_s3control_access_grants_instance.this.id
  grantee {
    grantee_type       = "DIRECTORY_GROUP"
    grantee_identifier = data.aws_identitystore_group.this.group_id
  }
}
