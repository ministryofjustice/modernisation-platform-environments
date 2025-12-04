# CUR Reports

module "cur_v2_hourly" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "coat-${local.environment}-cur-v2-hourly"

  force_destroy = true

  attach_deny_insecure_transport_policy = true
  attach_policy                         = true

  policy = local.is-development ? data.aws_iam_policy_document.coat_cur_v2_hourly_dev_bucket_policy.json : data.aws_iam_policy_document.coat_cur_v2_hourly_prod_bucket_policy.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.cur_s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }

  lifecycle_rule = [
    {
      id      = "DeleteOldVersions"
      enabled = true
      noncurrent_version_expiration = {
        days = 1
      }
    }
  ]
}

data "aws_iam_policy_document" "coat_cur_v2_hourly_dev_bucket_policy" {
  statement {
    sid    = "S3PutObject"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly"
    ]
    principals {
      type        = "Service"
      identifiers = ["bcm-data-exports.amazonaws.com"]
    }
  }
  statement {
    sid    = "S3ListGetObject"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = ["arn:aws:s3:::coat-${local.environment}-cur-v2-hourly"]
    principals {
      type        = "Service"
      identifiers = ["bcm-data-exports.amazonaws.com"]
    }
  }
  statement {
    sid    = "S3ReplicateObject"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.aws_organizations_root_account_id}:role/moj-cur-reports-v2-hourly-replication-role"]
    }
  }
  statement {
    sid    = "S3CrossAccountRoleAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.coat_prod_account_id}:role/moj-coat-${local.prod_environment}-cur-reports-cross-role"]
    }
  }
  statement {
    sid    = "AthenaAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/athena-results/*"
    ]
    principals {
      type        = "Service"
      identifiers = ["athena.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "coat_cur_v2_hourly_prod_bucket_policy" {
  statement {
    sid    = "S3PutObject"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly"
    ]
    principals {
      type        = "Service"
      identifiers = ["bcm-data-exports.amazonaws.com"]
    }
  }
  statement {
    sid    = "S3ListGetObject"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = ["arn:aws:s3:::coat-${local.environment}-cur-v2-hourly"]
    principals {
      type        = "Service"
      identifiers = ["bcm-data-exports.amazonaws.com"]
    }
  }
  statement {
    sid    = "S3ReplicateObject"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.aws_organizations_root_account_id}:role/moj-cur-reports-v2-hourly-replication-role"]
    }
  }
  statement {
    sid    = "S3CrossAccountRoleAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/moj-coat-${local.environment}-cur-reports-cross-role"]
    }
  }
  statement {
    sid    = "AthenaAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/athena-results/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/moj-cost-and-usage-reports/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*"
    ]
    principals {
      type = "Service"
      identifiers = [
        "athena.amazonaws.com",
        "glue.amazonaws.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# FOCUS Reports
module "focus_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/focus"]
  description           = "S3 FOCUS KMS key"
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowReplicationRole"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${local.environment_management.aws_organizations_root_account_id}:role/moj-focus-1-reports-replication-role"]
        }
      ]
    }
  ]

  deletion_window_in_days = 7

  tags = local.tags
}

data "aws_iam_policy_document" "focus_bucket_replication_policy" {
  #checkov:skip=CKV_AWS_356:resource "*" limited by condition
  statement {
    sid     = "focus_bucket_replication_policy"
    effect  = "Allow"
    actions = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:GetBucketVersioning", "s3:PutBucketVersioning"]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-focus-reports/*",
      "arn:aws:s3:::coat-${local.environment}-focus-reports"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.aws_organizations_root_account_id}:role/moj-focus-1-reports-replication-role"]
    }
  }
}

module "focus_reports" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket           = "coat-${local.environment}-focus-reports"
  object_ownership = "BucketOwnerEnforced"
  force_destroy    = true

  attach_deny_insecure_transport_policy = true
  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.focus_bucket_replication_policy.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.focus_s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }

  lifecycle_rule = [
    {
      id      = "DeleteOldVersions"
      enabled = true
      noncurrent_version_expiration = {
        days = 1
      }
    }
  ]
}

# COAT Reports 
module "coat_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/coat"]
  description           = "S3 COAT KMS key"
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowAdministrationKey"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CoatGithubActionsRole"]
        }
      ]
    }
  ]

  tags = local.tags
}

module "coat_reports" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket           = "coat-reports-${local.environment}"
  object_ownership = "BucketOwnerEnforced"
  force_destroy    = true

  attach_deny_insecure_transport_policy = true
  attach_policy                         = false

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.coat_s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }

  lifecycle_rule = [
    {
      id      = "DeleteOldVersions"
      enabled = true
      noncurrent_version_expiration = {
        days = 1
      }
    }
  ]
}

resource "aws_s3_object" "ebs_waste_reports" {
  bucket = module.coat_reports.s3_bucket_id
  key    = "ebs_waste_reports/"
  acl    = "private"
}

resource "aws_s3_object" "rds_waste_reports" {
  bucket = module.coat_reports.s3_bucket_id
  key    = "rds_waste_reports/"
  acl    = "private"
}

resource "aws_s3_object" "pod_waste_reports" {
  bucket = module.coat_reports.s3_bucket_id
  key    = "pod_waste_reports/"
  acl    = "private"
}

module "cur_v2_hourly_enriched" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  # No simple way to restirct the replication configuration to prod, so don't create bucket in dev
  count = local.is-development ? 0 : 1

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "coat-${local.environment}-cur-v2-hourly-enriched"

  force_destroy = true

  attach_deny_insecure_transport_policy = true
  attach_policy                         = true

  policy = local.is-development ? data.aws_iam_policy_document.coat_cur_v2_hourly_enriched_dev_bucket_policy.json : data.aws_iam_policy_document.coat_cur_v2_hourly_enriched_prod_bucket_policy.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.cur_s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }

  lifecycle_rule = [
    {
      id      = "DeleteOldVersions"
      enabled = true
      noncurrent_version_expiration = {
        days = 1
      }
    }
  ]

  replication_configuration = {
    role = module.cur_v2_hourly_enriched_replication_role.iam_role_arn

    rules = [
      {
        id       = "replicate-cur-v2-reports-enriched"
        status   = "Enabled"
        priority = 1
        filter = {
          prefix = ""
        }
        delete_marker_replication = true

        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }

        destination = {
          account_id    = "593291632749"
          bucket        = "arn:aws:s3:::mojap-data-production-coat-cur-reports-v2-hourly-enriched"
          storage_class = "STANDARD"
          access_control_translation = {
            owner = "Destination"
          }
          encryption_configuration = {
            replica_kms_key_id = "arn:aws:kms:eu-west-1:593291632749:key/0409ddbc-b6a2-46c4-a613-6145f6a16215"
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
}

data "aws_iam_policy_document" "coat_cur_v2_hourly_enriched_dev_bucket_policy" {
  statement {
    sid    = "S3PutObject"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched"
    ]
    principals {
      type        = "Service"
      identifiers = ["bcm-data-exports.amazonaws.com"]
    }
  }
  statement {
    sid    = "S3ListGetObject"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = ["arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched"]
    principals {
      type        = "Service"
      identifiers = ["bcm-data-exports.amazonaws.com"]
    }
  }
  statement {
    sid    = "S3ReplicateObject"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.aws_organizations_root_account_id}:role/moj-cur-reports-v2-hourly-replication-role"]
    }
  }
  statement {
    sid    = "S3CrossAccountRoleAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.coat_prod_account_id}:role/moj-coat-${local.prod_environment}-cur-reports-cross-role"]
    }
  }
  statement {
    sid    = "AthenaAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched/athena-results/*"
    ]
    principals {
      type        = "Service"
      identifiers = ["athena.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "coat_cur_v2_hourly_enriched_prod_bucket_policy" {
  statement {
    sid    = "S3PutObject"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched"
    ]
    principals {
      type        = "Service"
      identifiers = ["bcm-data-exports.amazonaws.com"]
    }
  }

  statement {
    sid    = "S3ListGetObject"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = ["arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched"]
    principals {
      type        = "Service"
      identifiers = ["bcm-data-exports.amazonaws.com"]
    }
  }

  statement {
    sid    = "S3ReplicateObject"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.aws_organizations_root_account_id}:role/moj-cur-reports-v2-hourly-replication-role"]
    }
  }

  statement {
    sid    = "S3CrossAccountRoleAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/moj-coat-${local.environment}-cur-reports-cross-role"]
    }
  }
  
  statement {
    sid    = "AthenaAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched/athena-results/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched/moj-cost-and-usage-reports/*",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched",
      "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly-enriched/*"
    ]
    principals {
      type = "Service"
      identifiers = [
        "athena.amazonaws.com",
        "glue.amazonaws.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AllowS3SyncAPDP"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetObjectTagging"
    ]
    resources = [
      "arn:aws:s3:::cur_v2_hourly_enriched",
      "arn:aws:s3:::cur_v2_hourly_enriched/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::593291632749:root"]
    }
  }
}

