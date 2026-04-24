
# ============================================================
# S3 Bucket
# ============================================================

resource "aws_s3_bucket" "files_bucket" {
  count         = contains(["preproduction", "development"], local.environment) ? 1 : 0
  bucket_prefix = "${local.application_name}-bucket-to-upload-ec2-files-"
  force_destroy = true


  tags = {
    Name        = "${local.application_name}-bucket-to-upload-ec2-files"
  }
}

# Block all public access (EC2 accesses via IAM role, not public URLs)
resource "aws_s3_bucket_public_access_block" "files_bucket" {
  count         = contains(["preproduction", "development"], local.environment) ? 1 : 0
  bucket = aws_s3_bucket.files_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



# Enable versioning (optional but recommended)
resource "aws_s3_bucket_versioning" "files_bucket" {
  count         = contains(["preproduction", "development"], local.environment) ? 1 : 0
  bucket = aws_s3_bucket.files_bucket[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "files_bucket" {
  count  = contains(["preproduction", "development"], local.environment) ? 1 : 0
  bucket = aws_s3_bucket.files_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


///bucket policy to allow only EC2 role to read from the bucket
resource "aws_s3_bucket_policy" "files_bucket" {
  count  = contains(["preproduction", "development"], local.environment) ? 1 : 0
  bucket = aws_s3_bucket.files_bucket[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowOnlyEC2Role"
        Effect    = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2_instance_role_new[0].arn
        }
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.files_bucket[0].arn,
          "${aws_s3_bucket.files_bucket[0].arn}/*"
        ]
      }
    ]
  })
}



///policy for EC2 role
resource "aws_iam_policy" "ec2_s3_reader" {
  count       = contains(["preproduction", "development"], local.environment) ? 1 : 0
  name        = "${local.application_name}-ec2-s3-reader-policy"
  description = "Allows EC2 to list and get objects from the files bucket only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # s3:GetObject works on objects inside the bucket (note the /*)
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.files_bucket[0].arn}/*"
      },
      {
        # s3:ListBucket works on the bucket itself (no /*)
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.files_bucket[0].arn
      }
    ]
  })
}



//adding poloicy to role 
resource "aws_iam_role_policy_attachment" "ec2_s3_reader" {
  count      = contains(["preproduction", "development"], local.environment) ? 1 : 0
  role       = aws_iam_role.ec2_instance_role_new[0].name
  policy_arn = aws_iam_policy.ec2_s3_reader[0].arn
}

