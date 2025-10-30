resource "aws_guardduty_malware_protection_plan" "s3_scan_bucket1" {
  role = data.aws_iam_role.guardduty_s3_scan.arn

  protected_resource {
    s3_bucket {
      bucket_name     = module.s3-bucket.bucket.id
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

  depends_on = [ module.s3-bucket ]
}

resource "aws_guardduty_malware_protection_plan" "s3_scan_bucket2" {
  role = data.aws_iam_role.guardduty_s3_scan.arn

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
    { Name = lower(format("s3-%s-%s-awsgaurdduty-mpp", "${local.application_data.accounts[local.environment].app_name}", local.environment)) }
  )

  depends_on = [ module.s3-bucket-logging ]
}

resource "aws_guardduty_malware_protection_plan" "s3_scan_bucket3" {
  role = data.aws_iam_role.guardduty_s3_scan.arn

  protected_resource {
    s3_bucket {
      bucket_name     = module.s3-bucket-dbbackup.bucket.id
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

  depends_on = [ module.s3-bucket-dbbackup ]
}

resource "aws_guardduty_malware_protection_plan" "s3_scan_bucket4" {
  role = data.aws_iam_role.guardduty_s3_scan.arn

  protected_resource {
    s3_bucket {
      bucket_name     = aws_s3_bucket.lambda_payment_load.id
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

  depends_on = [ aws_s3_bucket.lambda_payment_load ]
}

resource "aws_guardduty_malware_protection_plan" "s3_scan_bucket5" {
  for_each = aws_s3_bucket.buckets
  role = data.aws_iam_role.guardduty_s3_scan.arn

  protected_resource {
    s3_bucket {
      bucket_name     = each.value.id
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

  depends_on = [ aws_s3_bucket.buckets ]
}

resource "aws_guardduty_malware_protection_plan" "s3_scan_bucket6" {
  role = data.aws_iam_role.guardduty_s3_scan.arn

  protected_resource {
    s3_bucket {
      bucket_name     = aws_s3_bucket.red_button_data.id
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

  depends_on = [ aws_s3_bucket.red_button_data ]

}

data "aws_iam_role" "guardduty_s3_scan" {
  name = "GuardDutyS3MalwareProtectionRole"
}