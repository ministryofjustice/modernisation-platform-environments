resource "aws_guardduty_detector" "main" {
  enable = true
}

resource "aws_guardduty_malware_protection_plan" "s3_scan" {
  role = aws_iam_role.guardduty_s3_scan.arn

  protected_resource {
    s3_bucket {
      bucket_name     = module.s3-bucket-logging.bucket.id
    }
  }

  actions {
    tagging {
      status = "ENABLED"
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-logging", "${local.application_data.accounts[local.environment].app_name}", local.environment)) }
  )
}

resource "aws_iam_role" "guardduty_s3_scan" {
  name = "GuardDutyS3ScanRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "malware-protection-plan.guardduty.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "guardduty_s3_scan_policy" {
  name        = "GuardDutyS3ScanPolicy"
  description = "Allows GuardDuty to scan S3 bucket and tag objects"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3Access",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObjectTagging",
          "s3:GetBucketLocation"
        ],
        Resource = [
          "${module.s3-bucket-logging.bucket.arn}",
          "${module.s3-bucket-logging.bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_guardduty_policy" {
  role       = aws_iam_role.guardduty_s3_scan.name
  policy_arn = aws_iam_policy.guardduty_s3_scan_policy.arn
}
