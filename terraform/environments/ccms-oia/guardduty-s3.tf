resource "aws_guardduty_malware_protection_plan" "s3_scan_bucket1" {
  role = data.aws_iam_role.guardduty_s3_scan.arn

  protected_resource {
    s3_bucket {
      bucket_name = module.s3-bucket-logging.bucket.id
    }
  }

  actions {
    tagging {
      status = "ENABLED"
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-awsgaurdduty-mpp", "${local.application_data.accounts[local.environment].app_name}", local.environment)) }
  )

  depends_on = [module.s3-bucket-logging]
}



resource "aws_guardduty_malware_protection_plan" "s3_scan_bucket2" {
  role = data.aws_iam_role.guardduty_s3_scan.arn

  protected_resource {
    s3_bucket {
      bucket_name = module.s3_ccms_oia.bucket.id
    }
  }

  actions {
    tagging {
      status = "ENABLED"
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-awsgaurdduty-mpp", "${local.application_data.accounts[local.environment].app_name}", local.environment)) }
  )

  depends_on = [module.s3_ccms_oia]
}

data "aws_iam_role" "guardduty_s3_scan" {
  name = "GuardDutyS3MalwareProtectionRole"
}

resource "aws_guardduty_malware_protection_plan" "s3_scan_bucket3" {
  role = data.aws_iam_role.guardduty_s3_scan.arn

  protected_resource {
    s3_bucket {
      bucket_name = module.s3-bucket-shared.bucket.id
    }
  }

  actions {
    tagging {
      status = "ENABLED"
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-awsgaurdduty-mpp", "${local.application_data.accounts[local.environment].app_name}", local.environment)) }
  )

  depends_on = [module.s3-bucket-shared]
}