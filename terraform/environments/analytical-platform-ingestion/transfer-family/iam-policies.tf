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
    resources = [module.transfer_server_logs_kms.key_arn]
  }
}

module "transfer_server_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.54.1"

  name_prefix = "transfer-server"

  policy = data.aws_iam_policy_document.transfer_server.json
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

    resources = [
      "arn:aws:s3:::${module.transfer_landing_bucket.s3_bucket_id}/*"
    ]
  }

  statement {
    sid    = "AllowEnableS3EventBridgeEvents"
    effect = "Allow"

    actions = [
      "s3:PutBucketNotification",
      "s3:GetBucketNotification"
    ]

    resources = [
      "arn:aws:s3:::${module.transfer_landing_bucket.s3_bucket_id}"
    ]
  }

  statement {
    sid    = "AllowPutValidationObject"
    effect = "Allow"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${module.transfer_landing_bucket.s3_bucket_id}/malware-protection-resource-validation-object"
    ]
  }

  statement {
    sid    = "AllowCheckBucketOwnership"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${module.transfer_landing_bucket.s3_bucket_id}"
    ]
  }

  statement {
    sid    = "AllowMalwareScan"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]

    resources = [
      "arn:aws:s3:::${module.transfer_landing_bucket.s3_bucket_id}/*"
    ]
  }

  statement {
    sid    = "AllowDecryptForMalwareScan"
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = [
      module.s3_transfer_landing_kms.key_arn
    ]

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
  version = "5.44.1"

  name_prefix = "guard-duty-s3-malware-protection-transfer-${local.environment}-scan"

  policy = data.aws_iam_policy_document.guard_duty_malware_protection_iam_policy.json
}
