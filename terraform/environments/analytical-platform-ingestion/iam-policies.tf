data "aws_iam_policy_document" "transfer_server" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
    ]
    resources = [module.transfer_logs_kms.key_arn]
  }
}

module "transfer_server_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.3"

  name_prefix = "transfer-server"

  policy = data.aws_iam_policy_document.transfer_server.json
}

data "aws_iam_policy_document" "datasync" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
    ]
    resources = [module.s3_datasync_opg_kms.key_arn]
  }
  statement {
    sid    = "AllowS3BucketActions"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [module.datasync_opg_bucket.s3_bucket_arn]
  }
  statement {
    sid    = "AllowS3ObjectActions"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]
    resources = ["${module.datasync_opg_bucket.s3_bucket_arn}/*"]
  }
}

module "datasync_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.3"

  name_prefix = "datasync"

  policy = data.aws_iam_policy_document.datasync.json
}

data "aws_iam_policy_document" "datasync_replication" {
  statement {
    sid    = "DestinationBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:ReplicateDelete"
    ]
    resources = [
      for item in local.environment_configuration.datasync_target_buckets : "arn:aws:s3:::${item}/*"
    ]
  }
  statement {
    sid    = "DestinationBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [local.environment_configuration.mojap_land_kms_key]
  }
  statement {
    sid    = "SourceBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [module.s3_datasync_opg_kms.key_arn]
  }
  statement {
    sid    = "SourceBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [module.datasync_opg_bucket.s3_bucket_arn]
  }
  statement {
    sid    = "SourceBucketObjectPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${module.datasync_opg_bucket.s3_bucket_arn}/*"]
  }
}

module "datasync_replication_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.3"

  name_prefix = "datasync-replication"

  policy = data.aws_iam_policy_document.datasync_replication.json
}

data "aws_iam_policy_document" "datasync_opg_replication" {
  statement {
    sid    = "DestinationBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:ReplicateDelete"
    ]
    resources = [
      for item in local.environment_configuration.datasync_opg_target_buckets : "arn:aws:s3:::${item}/*"
    ]
  }
  statement {
    sid    = "DestinationBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [local.environment_configuration.datasync_opg_target_bucket_kms]
  }
  statement {
    sid    = "SourceBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [module.s3_datasync_opg_kms.key_arn]
  }
  statement {
    sid    = "SourceBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [module.datasync_opg_bucket.s3_bucket_arn]
  }
  statement {
    sid    = "SourceBucketObjectPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${module.datasync_opg_bucket.s3_bucket_arn}/*"]
  }
}

module "datasync_opg_replication_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.3"

  name_prefix = "datasync-opg-ingress-${local.environment}-replication"

  policy = data.aws_iam_policy_document.datasync_opg_replication.json
}

# GuardDuty Malware Protection Policy

data "aws_iam_policy_document" "guard_duty_malware_protection_iam_policy" {
  statement {
    sid    = "AllowManagedRuleToSendS3EventsToGuardDuty"
    effect = "Allow"

    actions = [
      "events:PutRule",
      "events:DeleteRule",
      "events:PutTargets",
      "events:RemoveTargets"
    ]

    resources = [
      "arn:aws:events:eu-west-2:${local.environment_management.account_ids[terraform.workspace]}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"
    ]

    condition {
      test     = "StringLike"
      variable = "events:ManagedBy"
      values   = ["malware-protection-plan.guardduty.amazonaws.com"]
    }
  }

  statement {
    sid    = "AllowGuardDutyToMonitorEventBridgeManagedRule"
    effect = "Allow"

    actions = [
      "events:DescribeRule",
      "events:ListTargetsByRule"
    ]

    resources = [
      "arn:aws:events:eu-west-2:${local.environment_management.account_ids[terraform.workspace]}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"
    ]
  }

  statement {
    sid    = "AllowPostScanTag"
    effect = "Allow"

    actions = [
      "s3:PutObjectTagging",
      "s3:GetObjectTagging",
      "s3:PutObjectVersionTagging",
      "s3:GetObjectVersionTagging"
    ]

    resources = compact([
      "arn:aws:s3:::${module.landing_bucket.s3_bucket_id}/*",
      local.environment == "production" ? "arn:aws:s3:::${module.laa_data_analysis_bucket[0].s3_bucket_id}/*" : ""
    ])
  }

  statement {
    sid    = "AllowEnableS3EventBridgeEvents"
    effect = "Allow"

    actions = [
      "s3:PutBucketNotification",
      "s3:GetBucketNotification"
    ]

    resources = compact([
      "arn:aws:s3:::${module.landing_bucket.s3_bucket_id}",
      local.environment == "production" ? "arn:aws:s3:::${module.laa_data_analysis_bucket[0].s3_bucket_id}" : ""
    ])
  }

  statement {
    sid    = "AllowPutValidationObject"
    effect = "Allow"

    actions = [
      "s3:PutObject"
    ]

    resources = compact([
      "arn:aws:s3:::${module.landing_bucket.s3_bucket_id}/malware-protection-resource-validation-object",
      local.environment == "production" ? "arn:aws:s3:::${module.laa_data_analysis_bucket[0].s3_bucket_id}/malware-protection-resource-validation-object" : ""
    ])
  }

  statement {
    sid    = "AllowCheckBucketOwnership"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = compact([
      "arn:aws:s3:::${module.landing_bucket.s3_bucket_id}",
      local.environment == "production" ? "arn:aws:s3:::${module.laa_data_analysis_bucket[0].s3_bucket_id}" : ""
    ])
  }

  statement {
    sid    = "AllowMalwareScan"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]

    resources = compact([
      "arn:aws:s3:::${module.landing_bucket.s3_bucket_id}/*",
      local.environment == "production" ? "arn:aws:s3:::${module.laa_data_analysis_bucket[0].s3_bucket_id}/*" : ""
    ])
  }

  statement {
    sid    = "AllowDecryptForMalwareScan"
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = compact([
      module.s3_landing_kms.key_arn,
      local.environment == "production" ? module.s3_laa_data_analysis_kms[0].key_arn : ""
    ])

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.eu-west-2.amazonaws.com"]
    }
  }
}

module "guard_duty_s3_malware_protection_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.3"

  name_prefix = "guard-duty-s3-malware-protection-${local.environment}-scan"

  policy = data.aws_iam_policy_document.guard_duty_malware_protection_iam_policy.json
}

data "aws_iam_policy_document" "laa_data_analysis" {
  # Only create this resource if we're in the production environment
  count = local.environment == "production" ? 1 : 0

  statement {
    sid    = "AllowSourceBucketKMSAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = jsondecode(data.aws_secretsmanager_secret_version.laa_data_analysis_keys[0].secret_string).keys
  }

  statement {
    sid    = "AllowSourceBucketListActions"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:GetBucketAcl"
    ]
    resources = [for bucket in jsondecode(data.aws_secretsmanager_secret_version.laa_data_analysis_bucket_list[0].secret_string).buckets : "arn:aws:s3:::${bucket}"]
  }

  statement {
    sid    = "AllowSourceBucketObjectActions"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging",
      "s3:ListMultipartUploadParts",
      "s3:GetObjectAcl",
      "s3:GetObjectVersionAcl"
    ]
    resources = [for bucket in jsondecode(data.aws_secretsmanager_secret_version.laa_data_analysis_bucket_list[0].secret_string).buckets : "arn:aws:s3:::${bucket}/*"]
  }

  statement {
    sid    = "AllowLAABucketActions"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]
    resources = [module.laa_data_analysis_bucket[0].s3_bucket_arn]
  }

  statement {
    sid    = "AllowLAABucketObjectActions"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]
    resources = ["${module.laa_data_analysis_bucket[0].s3_bucket_arn}/*"]
  }

  statement {
    sid    = "AllowLAABucketKMSActions"
    effect = "Allow"
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt"
    ]
    resources = [module.s3_laa_data_analysis_kms[0].key_arn]
  }
}

module "laa_data_analysis_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.3"

  name_prefix = "laa-data-analysis"

  policy = data.aws_iam_policy_document.laa_data_analysis[0].json
}

data "aws_iam_policy_document" "laa_data_analysis_replication" {
  # Only create this resource if we're in the production environment
  count = local.environment == "production" ? 1 : 0

  statement {
    sid    = "DestinationBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:ReplicateDelete",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:ReplicateMetadata" # Additional permission for preserving metadata
    ]
    resources = [
      for item in local.environment_configuration.laa_data_analysis_target_buckets : "arn:aws:s3:::${item}/*"
    ]
  }
  statement {
    sid    = "DestinationBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [local.environment_configuration.laa_data_analysis_target_bucket_kms]
  }
  statement {
    sid    = "SourceBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:ReEncrypt*"
    ]
    resources = [module.s3_laa_data_analysis_kms[0].key_arn]
  }
  statement {
    sid    = "SourceBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
      "s3:PutInventoryConfiguration",
      "s3:InitiateReplication"
    ]
    resources = [module.laa_data_analysis_bucket[0].s3_bucket_arn]
  }
  statement {
    sid    = "SourceBucketObjectPermissions"
    effect = "Allow"
    actions = [
      "s3:InitiateReplication",
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersion",
      "s3:GetObjectAcl",
      "s3:GetObject",        # for batch replication
      "s3:GetObjectTagging", # for batch replication
      "s3:PutObject",        # for batch replication
      "s3:PutObjectTagging"  # for batch replication
    ]
    resources = ["${module.laa_data_analysis_bucket[0].s3_bucket_arn}/*"]
  }
}

module "laa_data_analysis_replication_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.3"

  name_prefix = "laa-data-analysis-${local.environment}-replication"

  policy = data.aws_iam_policy_document.laa_data_analysis_replication[0].json
}


