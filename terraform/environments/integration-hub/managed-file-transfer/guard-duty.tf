resource "aws_guardduty_malware_protection_plan" "this" {
  role = module.guardduty_s3_plan_role.arn

  protected_resource {
    s3_bucket {
      bucket_name     = module.s3_bucket["processing"].s3_bucket_id
      object_prefixes = local.iam_configuration.malware_scanning_object_prefix
    }
  }

  actions {
    tagging {
      status = "ENABLED"
    }
  }
}