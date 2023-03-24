/*
#----------------------------------------------------------
# S3 Bucket for Files copying between the PPUD Environment
#----------------------------------------------------------

resource "aws_s3_bucket" "PPUD" {
  count  = local.is-production == true ? 1 : 0
  bucket = "${local.application_name}-PPUD-Files-${local.environment}"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-PPUD-S3"
    }
  )
}

resource "aws_s3_bucket_acl" "PPUD_ACL" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.PPUD.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "PPUD" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.PPUD.id
  rule {
    id     = "tf-s3-lifecycle"
    status = "Enabled"
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }
  }
}


#S3 bucket access policy
resource "aws_iam_policy" "PPUD_s3_policy" {
  count  = local.is-production == true ? 1 : 0
  name   = "${local.application_name}-PPUD_s3_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
     {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
        "s3:GetObjectMetaData",
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload"
      ],
    "Resource": [
        "${aws_s3_bucket.PPUD.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "PPUD_s3_role" {
  count  = local.is-production == true ? 1 : 0
  name               = "${local.application_name}-PPUD_s3_role"
  assume_role_policy = data.aws_iam_policy_document.s3-access-policy.json
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-PPUD_s3_role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "PPUD_s3_attachment" {
  count  = local.is-production == true ? 1 : 0
  role       = aws_iam_role.PPUD_s3_role.name
  policy_arn = aws_iam_policy.PPUD_s3_policy.arn
}

*/