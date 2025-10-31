data "aws_iam_policy_document" "landing_bucket_policy" {
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
      "arn:aws:s3:::mojap-ingestion-${local.environment}-landing/*",
      "arn:aws:s3:::mojap-ingestion-${local.environment}-landing"
    ]
  }
}
module "landing_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.1.0"

  bucket = "mojap-ingestion-${local.environment}-landing"

  force_destroy = true
  attach_policy = true
  policy        = data.aws_iam_policy_document.landing_bucket_policy.json

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
      "arn:aws:s3:::mojap-ingestion-${local.environment}-quarantine/*",
      "arn:aws:s3:::mojap-ingestion-${local.environment}-quarantine"
    ]
  }
}

module "quarantine_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.1.0"

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
  version = "5.1.0"

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

data "aws_iam_policy_document" "processed_bucket_policy" {
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
      "arn:aws:s3:::mojap-ingestion-${local.environment}-processed/*",
      "arn:aws:s3:::mojap-ingestion-${local.environment}-processed"
    ]
  }
}

module "processed_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.1.0"

  bucket = "mojap-ingestion-${local.environment}-processed"

  force_destroy = true
  attach_policy = true
  policy        = data.aws_iam_policy_document.processed_bucket_policy.json

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
      "arn:aws:s3:::mojap-ingestion-${local.environment}-bold-egress/*",
      "arn:aws:s3:::mojap-ingestion-${local.environment}-bold-egress"
    ]
  }
}

#tfsec:ignore:avd-aws-0088 - The bucket policy is attached to the bucket
#tfsec:ignore:avd-aws-0132 - The bucket policy is attached to the bucket
module "bold_egress_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.1.0"

  bucket = "mojap-ingestion-${local.environment}-bold-egress"

  force_destroy = true
  attach_policy = true

  versioning = {
    enabled = true
  }

  policy = data.aws_iam_policy_document.bold_egress_bucket_policy.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_bold_egress_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

data "aws_iam_policy_document" "datasync_opg_policy" {
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
      "arn:aws:s3:::mojap-ingestion-${local.environment}-datasync-opg/*",
      "arn:aws:s3:::mojap-ingestion-${local.environment}-datasync-opg"
    ]
  }
}

module "datasync_opg_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.1.0"

  bucket = "mojap-ingestion-${local.environment}-datasync-opg"

  force_destroy = true
  attach_policy = true
  policy        = data.aws_iam_policy_document.datasync_opg_policy.json

  versioning = {
    enabled = true
  }

  replication_configuration = {
    role = module.datasync_opg_replication_iam_role.iam_role_arn
    rules = [
      {
        id                        = "datasync-opg-replication"
        status                    = "Enabled"
        delete_marker_replication = true

        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }

        destination = {
          account_id    = local.environment_management.account_ids["analytical-platform-data-production"]
          bucket        = "arn:aws:s3:::${local.environment_configuration.datasync_opg_target_buckets[0]}"
          storage_class = "STANDARD"
          access_control_translation = {
            owner = "Destination"
          }
          encryption_configuration = {
            replica_kms_key_id = local.environment_configuration.datasync_opg_target_bucket_kms
          }
          metrics = {
            status  = "Enabled"
            minutes = 15
          }
          replication_time = {
            status  = "Enabled"
            minutes = 15
          }
        }
      }
    ]
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_datasync_opg_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

data "aws_iam_policy_document" "laa_data_analysis_bucket_policy" {
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
      "arn:aws:s3:::mojap-ingestion-${local.environment}-laa-data-analysis/*",
      "arn:aws:s3:::mojap-ingestion-${local.environment}-laa-data-analysis"
    ]
  }
}

# Create S3 bucket for LAA data analysis
module "laa_data_analysis_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.1.0"

  bucket = "mojap-ingestion-${local.environment}-laa-data-analysis"

  force_destroy = true
  attach_policy = true
  policy        = data.aws_iam_policy_document.laa_data_analysis_bucket_policy.json

  versioning = {
    enabled = true
  }

  replication_configuration = {
    role = module.laa_data_analysis_replication_iam_role[0].iam_role_arn
    rules = [
      {
        id     = "laa-data-analysis-replication"
        status = "Enabled"

        delete_marker_replication = false

        # Only replicate objects with GuardDutyMalwareScanStatus = NO_THREATS_FOUND tag
        filter = {
          tag = {
            "GuardDutyMalwareScanStatus" = "NO_THREATS_FOUND"
          }
        }

        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }

        destination = {
          account_id    = local.environment_management.account_ids["analytical-platform-data-production"]
          bucket        = "arn:aws:s3:::${local.environment_configuration.laa_data_analysis_target_buckets[0]}"
          storage_class = "STANDARD"
          access_control_translation = {
            owner = "Destination"
          }
          encryption_configuration = {
            replica_kms_key_id = local.environment_configuration.laa_data_analysis_target_bucket_kms
          }
          metrics = {
            status  = "Enabled"
            minutes = 15
          }
          replication_time = {
            status  = "Enabled"
            minutes = 15
          }
        }
      }
    ]
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_laa_data_analysis_kms[0].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  attach_inventory_destination_policy = true
  inventory_self_source_destination   = true

  inventory_configuration = {
    laa-data-analysis-inventory-csv = {
      included_object_versions = "All"

      destination = {
        format = "CSV"
        prefix = "inventory/csv/"
      }


      frequency = "Weekly"

      optional_fields = [
        "Size",
        "LastModifiedDate",
        "StorageClass",
        "ETag",
        "IsMultipartUploaded",
        "ReplicationStatus",
        "EncryptionStatus",
        "ObjectLockRetainUntilDate",
        "ObjectLockMode",
        "ObjectLockLegalHoldStatus",
        "IntelligentTieringAccessTier",
        "BucketKeyStatus",
        "ChecksumAlgorithm",
        "ObjectAccessControlList",
        "ObjectOwner"
      ]
    },

    laa-data-analysis-inventory-parquet = {
      included_object_versions = "All"

      destination = {
        format = "Parquet"
        prefix = "inventory/parquet/"
      }

      frequency = "Weekly"

      optional_fields = [
        "Size",
        "LastModifiedDate",
        "StorageClass",
        "ETag",
        "IsMultipartUploaded",
        "ReplicationStatus",
        "EncryptionStatus",
        "ObjectLockRetainUntilDate",
        "ObjectLockMode",
        "ObjectLockLegalHoldStatus",
        "IntelligentTieringAccessTier",
        "BucketKeyStatus",
        "ChecksumAlgorithm",
        "ObjectAccessControlList",
        "ObjectOwner"
      ]
    }
  }

  tags = local.tags
}

data "aws_iam_policy_document" "shared_services_client_team_gov_29148_egress" {

  count = local.is-production ? 1 : 0

  statement {
    sid    = "ReplicationPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::593291632749:role/mojap-data-production-ssct-gov-29148-egress"]
    }
    actions = [
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:ReplicateDelete"
    ]
    resources = ["arn:aws:s3:::mojap-ingestion-${local.environment}-ssct-gov-29148-egress/*"]
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
      "arn:aws:s3:::mojap-ingestion-${local.environment}-ssct-gov-29148-egress/*",
      "arn:aws:s3:::mojap-ingestion-${local.environment}-ssct-gov-29148-egress"
    ]
  }
}

#tfsec:ignore:avd-aws-0088 - The bucket policy is attached to the bucket
#tfsec:ignore:avd-aws-0132 - The bucket policy is attached to the bucket
module "shared_services_client_team_gov_29148_egress_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  count = local.is-production ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.1.0"

  bucket = "mojap-ingestion-${local.environment}-ssct-gov-29148-egress"

  force_destroy = true
  attach_policy = true

  versioning = {
    enabled = true
  }

  policy = data.aws_iam_policy_document.shared_services_client_team_gov_29148_egress[0].json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.shared_services_client_team_gov_29148_egress_kms[0].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
