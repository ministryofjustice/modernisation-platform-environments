### S3 BUCKET FOR WORKSPACES WEB SESSION LOGGING

module "s3_bucket_workspacesweb_session_logs" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "laa-workspacesweb-session-logs-${random_string.bucket_suffix.result}"

  # Versioning
  versioning = {
    enabled = true
  }

  # Server side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Public access block
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Lifecycle configuration
  lifecycle_rule = [{
    id     = "session_logs_lifecycle"
    status = "Enabled"

    expiration = {
      days = 365
    }

    noncurrent_version_expiration = {
      days = 30
    }
  }]

  # Bucket policy to allow WorkSpaces Web service access
  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowWorkSpacesWebServiceAccess"
        Effect = "Allow"
        Principal = {
          Service = "workspaces-web.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::laa-workspacesweb-session-logs-${random_string.bucket_suffix.result}",
          "arn:aws:s3:::laa-workspacesweb-session-logs-${random_string.bucket_suffix.result}/*"
        ]
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "laa-workspacesweb-session-logs"
    }
  )
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}