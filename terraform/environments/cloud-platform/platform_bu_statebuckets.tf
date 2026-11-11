locals {
  bu_accounts = jsondecode(
    file("${path.module}/accounts.json")
  ).accounts

  bu_live_accounts = {
    for account in local.bu_accounts :
    trimsuffix(
      replace(account, "container-platform-", ""),
      "-live"
    ) => {
      workspace  = account
      account_id = local.environment_management.account_ids[account]
    }
    if endswith(account, "-live")
  }

  state_bucket_enabled = contains(
    [for account in values(local.bu_live_accounts) : account.workspace],
    terraform.workspace
  )

  current_business_unit = local.state_bucket_enabled ? upper(one([
    for bu, account in local.bu_live_accounts :
    bu
    if account.workspace == terraform.workspace
  ])) : "Platforms"
}

module "state_bucket" {
  count  = local.state_bucket_enabled ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  providers = {
    aws.bucket-replication = aws
  }

  # Keep the prefix within the S3 module's 37-character limit.
  bucket_name        = "${terraform.workspace}-tf-state"
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  versioning_enabled  = true

  sse_algorithm               = "aws:kms"
  custom_kms_key              = aws_kms_key.state[0].arn
  enforce_kms_request_headers = false

  lifecycle_rule = [
    {
      id      = "disable-lifecycle"
      enabled = "Disabled"
    }
  ]

  tags = merge(local.tags, {
    business-unit = local.current_business_unit
    Purpose       = "Terraform state"
  })
}

resource "aws_kms_key" "state" {
  count = local.state_bucket_enabled ? 1 : 0

  description             = "KMS key for Terraform state bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = merge(local.tags, {
    business-unit = local.current_business_unit
    Purpose       = "Terraform state"
  })
}
