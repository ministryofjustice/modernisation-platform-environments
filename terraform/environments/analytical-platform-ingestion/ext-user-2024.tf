#tfsec:ignore:avd-aws-0088 - The bucket policy is attached to the bucket
#tfsec:ignore:avd-aws-0132 - The bucket policy is attached to the bucket
module "ext_2024_egress_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = "mojap-ingestion-${local.environment}-ext-2024-egress"

  force_destroy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_ext_2024_egress_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

module "s3_ext_2024_egress_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["s3/ext-2024-egress"]
  description           = "Used in the External 2024 Egress Solution"
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowReadOnlyRole"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/security-read-only"]
        }
      ]
    }
  ]
  deletion_window_in_days = 7
}

data "aws_iam_policy_document" "ext_2024_target_bucket_policy" {
  statement {
    sid    = "LandingPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::471112983409:role/transfer"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:PutObjectTagging"
    ]
    resources = [
      "arn:aws:s3:::mojap-ingestion-${local.environment}-ext-2024-target/*",
      "arn:aws:s3:::mojap-ingestion-${local.environment}-ext-2024-target"
    ]
  }
}

#tfsec:ignore:avd-aws-0088 - The bucket policy is attached to the bucket
#tfsec:ignore:avd-aws-0132 - The bucket policy is attached to the bucket
module "ext_2024_target_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = "mojap-ingestion-${local.environment}-ext-2024-target"

  force_destroy = true

  versioning = {
    enabled = true
  }
  attach_policy = true
  policy        = data.aws_iam_policy_document.ext_2024_target_bucket_policy.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}
