# ---------------------------------------------
# GuardDuty Malware Protection Plans
# ---------------------------------------------

resource "aws_guardduty_malware_protection_plan" "s3_scan_bucket1" {
  role = data.aws_iam_role.guardduty_s3_scan.arn

  protected_resource {
    s3_bucket {
      bucket_name = module.s3-bucket-sftp-bc.bucket.id
    }
  }

  actions {
    tagging {
      status = "ENABLED"
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-awsgaurdduty-mpp", "${local.sftp_suffix}", local.environment)) }
  )

  depends_on = [module.s3-bucket-sftp-bc]
}

data "aws_iam_role" "guardduty_s3_scan" {
  name = "GuardDutyS3MalwareProtectionRole"
}
