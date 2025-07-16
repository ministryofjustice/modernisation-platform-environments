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
  version = "5.2.0"

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
