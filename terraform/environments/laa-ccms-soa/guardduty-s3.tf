# resource "aws_guardduty_detector" "main" {
#   enable = true
#   finding_publishing_frequency = "SIX_HOURS"
#   #  tags = merge(local.tags,
#   #   { Name = lower(format("s3-%s-%s-awsgaurdduty-detector", "${local.application_data.accounts[local.environment].app_name}", local.environment)) }
#   # )

# }

resource "aws_guardduty_malware_protection_plan" "s3_scan" {
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

data "aws_iam_role" "guardduty_s3_scan" {
  name = "AWSServiceRoleForAmazonGuardDuty"
}