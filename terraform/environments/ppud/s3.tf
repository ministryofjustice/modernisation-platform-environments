
###########################################################
# S3 Bucket for Files copying between the PPUD Environments
###########################################################

resource "aws_s3_bucket" "PPUD" {
  count  = local.is-production == true ? 1 : 0
  bucket = "${local.application_name}-ppud-files-${local.environment}"

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

resource "aws_s3_bucket_versioning" "PPUD" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.PPUD[0].id
  versioning_configuration {
    status = "Enabled"
  }
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
            "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/sandbox",
            "arn:aws:iam::${local.environment_management.account_ids["ppud-preproduction"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["ppud-preproduction"]}:role/migration",
            "arn:aws:iam::${local.environment_management.account_ids["ppud-production"]}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["ppud-production"]}:role/migration"
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


###################################################
# MoJ- Patch Manager Health-Check-Reports S3 Bucket
###################################################

# Create S3 Bucket for SSM Health Check Reports

resource "aws_s3_bucket" "MoJ-Health-Check-Reports" {
  bucket = local.application_data.accounts[local.environment].ssm_health_check_reports_s3
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-health-check-reports"
    }
  )
}

resource "aws_s3_bucket_versioning" "MoJ-Health-Check-Reports" {
  bucket = aws_s3_bucket.MoJ-Health-Check-Reports.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Lifecycle Configuration for SSM Health Check Reports

resource "aws_s3_bucket_lifecycle_configuration" "MoJ-Health-Check-Reports" {
  bucket = aws_s3_bucket.MoJ-Health-Check-Reports.id
  rule {
    id     = "Remove_Old_SSM_Health_Check_Reports"
    status = "Enabled"

    filter {
      prefix = "ssm_output/"
    }

    noncurrent_version_transition {
      noncurrent_days = 183
      storage_class   = "STANDARD_IA"
    }

    transition {
      days          = 183
      storage_class = "STANDARD_IA"
    }
  }
}

# S3 block public access

resource "aws_s3_bucket_public_access_block" "MoJ-Health-Check-Reports" {
  bucket                  = aws_s3_bucket.MoJ-Health-Check-Reports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


#########################
# MoJ- Scripts S3 Bucket
#########################

resource "aws_s3_bucket" "moj-scripts" {
  count  = local.is-production == true ? 1 : 0
  bucket = "moj-scripts"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-scripts"
    }
  )
}

resource "aws_s3_bucket_versioning" "moj-scripts" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-scripts[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "moj-scripts" {
  count                   = local.is-production == true ? 1 : 0
  bucket                  = aws_s3_bucket.moj-scripts[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "moj-scripts" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.moj-scripts[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-scripts",
          "arn:aws:s3:::moj-scripts/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/ec2-iam-role",
            "arn:aws:iam::${local.environment_management.account_ids["ppud-preproduction"]}:role/ec2-iam-role"
          ]
        }
      }
    ]
  })
}


####################################
# MoJ- Release-Management S3 Bucket
####################################

resource "aws_s3_bucket" "MoJ-Release-Management" {
  count  = local.is-production == true ? 1 : 0
  bucket = "moj-release-management"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-moj-release-management"
    }
  )
}

resource "aws_s3_bucket_versioning" "MoJ-Release-Management" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.MoJ-Release-Management[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "MoJ-Release-Management" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.MoJ-Release-Management[0].id
  rule {
    id     = "Remove_Old_MoJ-Release-Management"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "MoJ-Release-Management" {
  count                   = local.is-production == true ? 1 : 0
  bucket                  = aws_s3_bucket.MoJ-Release-Management[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "MoJ-Release-Management" {
  count  = local.is-production == true ? 1 : 0
  bucket = aws_s3_bucket.MoJ-Release-Management[0].id

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::moj-release-management",
          "arn:aws:s3:::moj-release-management/*"
        ],
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-development"]}:role/ec2-iam-role",
            "arn:aws:iam::${local.environment_management.account_ids["ppud-preproduction"]}:role/ec2-iam-role"
          ]
        }
      }
    ]
  })
}