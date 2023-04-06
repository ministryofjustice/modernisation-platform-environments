
#----------------------------------------------------------
# S3 Bucket for Files copying between the PPUD Environments
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
  bucket = aws_s3_bucket.PPUD[0].id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "PPUD" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.PPUD[0].id
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


# S3 block public access
resource "aws_s3_bucket_public_access_block" "PPUD" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.PPUD[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy

resource "aws_s3_bucket_policy" "PPUD" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.PPUD[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
          "arn:aws:iam::075585660276:role/developer",
          "arn:aws:iam::075585660276:role/sandbox",
          "arn:aws:iam::172753231260:role/migration",
          "arn:aws:iam::172753231260:role/developer",
          "arn:aws:iam::817985104434:role/migration",
          "arn:aws:iam::817985104434:role/developer"
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.PPUD[0].arn}/*"
      }
    ]
  })
}


#S3 bucket IAM policy
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
        "s3:DeleteObject",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload"
      ],
    "Resource": [
        "${aws_s3_bucket.PPUD[0].arn}/*"
      ]
    }
  ]
}
EOF
}


resource "aws_iam_role" "PPUD_s3_role" {
  count  = local.is-production == true ? 1 : 0
  name   = "${local.application_name}-PPUD_s3_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
          "arn:aws:iam::075585660276:role/developer",
          "arn:aws:iam::075585660276:role/sandbox",
          "arn:aws:iam::172753231260:role/migration",
          "arn:aws:iam::172753231260:role/developer",
          "arn:aws:iam::817985104434:role/migration",
          "arn:aws:iam::817985104434:role/developer"
          ]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


/*
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


data "aws_iam_policy_document" "s3-access-policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      AWS = [
      "arn:aws:iam::075585660276:role/developer",
      "arn:aws:iam::075585660276:role/sandbox",
      "arn:aws:iam::172753231260:role/migration",
      "arn:aws:iam::172753231260:role/developer",
      "arn:aws:iam::817985104434:role/migration",
      "arn:aws:iam::817985104434:role/developer"
    ]
  }
 }
}
*/

resource "aws_iam_role_policy_attachment" "PPUD_s3_attachment" {
  count      = local.is-production == true ? 1 : 0
  role       = aws_iam_role.PPUD_s3_role[0].name
  policy_arn = aws_iam_policy.PPUD_s3_policy[0].arn
}