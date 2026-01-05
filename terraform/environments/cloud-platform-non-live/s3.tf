# Development clusters state bucket

resource "aws_kms_key" "development_cluster_s3_state_bucket" {
  count                   = local.is-development ? 1 : 0
  description             = "development-cluster-s3-state-bucket"
  policy                  = data.aws_iam_policy_document.development_cluster_s3_kms_state_bucket.json
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "development_cluster_s3_state_bucket" {
  count         = local.is-development ? 1 : 0
  name          = "alias/development-cluster-s3-state-bucket"
  target_key_id = aws_kms_key.development_cluster_s3_state_bucket[0].id
}

data "aws_iam_policy_document" "development_cluster_s3_kms_state_bucket" {
  # checkov:skip=CKV_AWS_111: "policy is directly related to the resource"
  # checkov:skip=CKV_AWS_356: "policy is directly related to the resource"
  # checkov:skip=CKV_AWS_109: "role is resticted by limited actions in the account"
  statement {
    sid    = "Allow management access of the key to the cloud platform non-live account"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

module "development-cluster-state-bucket" {
  count  = local.is-development ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399" # v9.0.0

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix      = "development-clusters-terraform-state"
  suffix_name        = "development-clusters-tf"
  custom_kms_key     = aws_kms_key.development_cluster_s3_state_bucket[0].arn
  ownership_controls = "BucketOwnerEnforced"
  tags               = local.tags

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""
      tags    = {}
      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 700
          storage_class = "GLACIER"
        }
      ]
      expiration = {
        days = 730
      }
      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 700
          storage_class = "GLACIER"
        }
      ]
      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]
}
