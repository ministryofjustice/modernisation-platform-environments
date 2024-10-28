module "mlflow_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.1"

  bucket = "mojap-compute-${local.environment}-mlflow"

  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.mlflow_s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = local.tags
}

# data "aws_iam_policy_document" "s3_replication_policy" {
#   #checkov:skip=CKV_AWS_356:resource "*" being applied to replication iam role only
#   statement {
#     sid    = "AllowLakeFormationPrincipalsReplication"
#     effect = "Allow"
#     actions = [
#       "s3:ReplicateTags",
#       "s3:ReplicateDelete",
#       "s3:ReplicateObject"
#     ]
#     principals {
#       type = "AWS"
#       identifiers = [
#         "arn:aws:iam::525294151996:role/service-role/s3replicate_role_for_lf-antfmoj-test",
#         "arn:aws:iam::525294151996:role/service-role/s3crr_role_for_lf-antfmoj-test_1"
#       ]
#     }
#     resources = ["arn:aws:s3:::mojap-compute-${local.environment}-derived-tables-replication/*"]
#   }
# }

# module "mojap_derived_tables_replication_bucket" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#   #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

#   source  = "terraform-aws-modules/s3-bucket/aws"
#   version = "4.2.1"

#   providers = {
#     aws = aws.analytical-platform-compute-eu-west-1
#   }

#   bucket = "mojap-compute-${local.environment}-derived-tables-replication"

#   force_destroy = true

#   attach_policy = true
#   policy        = data.aws_iam_policy_document.s3_replication_policy.json

#   object_lock_enabled = false

#   versioning = {
#     status = "Enabled"
#   }

#   server_side_encryption_configuration = {
#     rule = {
#       bucket_key_enabled = true
#       apply_server_side_encryption_by_default = {
#         kms_master_key_id = module.mojap_derived_tables_replication_s3_kms.key_arn
#         sse_algorithm     = "aws:kms"
#       }
#     }
#   }

#   logging = {
#     target_bucket = module.mojap_compute_logs_bucket.s3_bucket_id
#     target_prefix = "mojap-derived-tables-replication/"
#   }

#   tags = local.tags
# }

data "aws_iam_policy_document" "s3_server_access_logs_policy" {
  #checkov:skip=CKV_AWS_356:resource "*" limited by condition
  statement {
    sid       = "S3ServerAccessLogsPolicy"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::mojap-compute-${local.environment}-logs/*"]
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

module "mojap_compute_logs_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.1"

  bucket = "mojap-compute-${local.environment}-logs"

  force_destroy = false

  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_server_access_logs_policy.json

  object_lock_enabled = false

  versioning = {
    status = "Disabled"
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.mojap_compute_logs_s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = local.tags
}
