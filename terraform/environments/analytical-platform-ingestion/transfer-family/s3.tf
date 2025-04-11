data "aws_iam_policy_document" "transfer_landing_bucket_policy" {
  statement {
    sid    = "DenyS3AccessSandbox"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = [local.environment == "development" ? "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/sandbox" : "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/developer"]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::mojap-transfer-${local.environment}-landing/*",
      "arn:aws:s3:::mojap-transfer-${local.environment}-landing"
    ]
  }
}

module "transfer_landing_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "mojap-transfer-${local.environment}-landing"

  force_destroy = true
  attach_policy = true
  policy        = data.aws_iam_policy_document.transfer_landing_bucket_policy.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_transfer_landing_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

data "aws_iam_policy_document" "transfer_quarantine_bucket_policy" {
  statement {
    sid    = "DenyAccess"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObjectTagging"
    ]
    resources = ["arn:aws:s3:::mojap-transfer-${local.environment}-quarantine/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:ExistingObjectTag/scan-result"
      values   = ["infected"]
    }
  }
  statement {
    sid    = "DenyS3AccessSandbox"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = [local.environment == "development" ? "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/sandbox" : "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/developer"]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::mojap-transfer-${local.environment}-quarantine/*",
      "arn:aws:s3:::mojap-transfer-${local.environment}-quarantine"
    ]
  }
}

module "transfer_quarantine_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "mojap-transfer-${local.environment}-quarantine"

  force_destroy = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.transfer_quarantine_bucket_policy.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_transfer_quarantine_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "delete-infected-objects-after-90-days"
      enabled = true

      expiration = {
        days = 90
      }
    }
  ]
}