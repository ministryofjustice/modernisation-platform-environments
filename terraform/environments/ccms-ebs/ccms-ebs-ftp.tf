### secrets for ftp user and password
resource "aws_secretsmanager_secret" "ftp_password" {
  name        = lower(format("laa-ccms-ebs-ftp-password-%s",local.environment))
  description = "A secret for storing ftp server password"
}

resource "aws_secretsmanager_secret" "ftp_user" {
  name        = lower(format("laa-ccms-ebs-ftp-user-%s",local.environment))
  description = "A secret for storing ftp server user"
}




#### bucket for laa-ccms-inbound for storing files from lambda
resource "aws_s3_bucket" "inbound_bucket" {
  bucket = lower(format("laa-ccms-inbound-%s-mp",local.environment))  # ccms inbound bucket

}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket_encryption" {
  bucket = aws_s3_bucket.inbound_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
