module "landing_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "mojap-ingestion-${local.environment}-landing"

  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_landing_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

data "aws_iam_policy_document" "quarantine_bucket_policy" {
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
    resources = ["arn:aws:s3:::mojap-ingestion-${local.environment}-quarantine/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:ExistingObjectTag/scan-result"
      values   = ["infected"]
    }
  }
}

module "quarantine_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "mojap-ingestion-${local.environment}-quarantine"

  force_destroy = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.quarantine_bucket_policy.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_quarantine_kms.key_arn
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

module "definitions_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "mojap-ingestion-${local.environment}-definitions"

  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_definitions_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

module "processed_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "mojap-ingestion-${local.environment}-processed"

  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_processed_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

data "aws_iam_policy_document" "bold_egress_bucket_policy" {
  statement {
    sid    = "ReplicationPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::593291632749:role/mojap-data-production-bold-egress-${local.environment}"]
    }
    actions = [
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:ReplicateDelete"
    ]
    resources = ["arn:aws:s3:::mojap-ingestion-${local.environment}-bold-egress/*"]
  }
}

#tfsec:ignore:avd-aws-0088 - The bucket policy is attached to the bucket
#tfsec:ignore:avd-aws-0132 - The bucket policy is attached to the bucket
module "bold_egress_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "mojap-ingestion-${local.environment}-bold-egress"

  force_destroy = true

  versioning = {
    enabled = true
  }

  attach_policy = true
  policy        = data.aws_iam_policy_document.bold_egress_bucket_policy.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_bold_egress_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

module "datasync_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "mojap-ingestion-${local.environment}-datasync"

  force_destroy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_datasync_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}


module "datasync_opg_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "mojap-ingestion-${local.environment}-datasync-opg"

  force_destroy = true

  # versioning = {
  #   enabled = true
  # }

  # replication_configuration = {
  #   role = module.datasync_replication_iam_role.iam_role_arn
  #   rules = [
  #     {
  #       id                        = "datasync-replication"
  #       status                    = "Enabled"
  #       delete_marker_replication = true

  #       source_selection_criteria = {
  #         sse_kms_encrypted_objects = {
  #           enabled = true
  #         }
  #       }

  #       destination = {
  #         account_id    = local.environment_management.account_ids["analytical-platform-data-production"]
  #         bucket        = "arn:aws:s3:::${local.environment_configuration.datasync_target_buckets[0]}"
  #         storage_class = "STANDARD"
  #         access_control_translation = {
  #           owner = "Destination"
  #         }
  #         encryption_configuration = {
  #           replica_kms_key_id = local.environment_configuration.mojap_land_kms_key
  #         }
  #         metrics = {
  #           status  = "Enabled"
  #           minutes = 15
  #         }
  #         replication_time = {
  #           status  = "Enabled"
  #           minutes = 15
  #         }
  #       }
  #     }
  #   ]
  # }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_datasync_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
