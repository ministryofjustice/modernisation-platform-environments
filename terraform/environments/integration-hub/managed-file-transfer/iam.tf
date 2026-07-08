module "guardduty_s3_plan_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.1"

  name        = "${local.application_name}-${local.environment}-guardduty-s3-plan"
  description = "GuardDuty S3 malware protection plan policy"
  path        = "/"

  policy = data.aws_iam_policy_document.guardduty_s3_plan_permission_policy.json

  tags = local.tags
}

module "guardduty_s3_plan_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  create          = true
  use_name_prefix = false
  name            = "${local.application_name}-${local.environment}-guardduty-s3-plan"

  trust_policy_permissions = {
    AllowGuardDutyService = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["malware-protection-plan.guardduty.amazonaws.com"]
      }]
    }
  }

  policies = {
    guardduty_s3_plan = module.guardduty_s3_plan_policy.arn
  }

  tags = local.tags
}

data "aws_iam_policy_document" "guardduty_s3_plan_permission_policy" {
  # Guardduty event permissions
  statement {
    effect = "Allow"
    actions = [
      "events:PutRule",
      "events:DeleteRule",
      "events:PutTargets",
      "events:RemoveTargets"
    ]
    resources = ["arn:aws:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "events:DescribeRule",
      "events:ListTargetsByRule"
    ]
    resources = [
    "arn:aws:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"]
  }
  # s3 read permissions
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObjectTagging",
      "s3:GetObjectTagging",
      "s3:PutObjectVersionTagging",
      "s3:GetObjectVersionTagging"
    ]
    resources = [
      "${module.s3_bucket["processing"].s3_bucket_arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutBucketNotification",
      "s3:GetBucketNotification"
    ]
    resources = [
      "${module.s3_bucket["processing"].s3_bucket_arn}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.s3_bucket["processing"].s3_bucket_arn}/malware-protection-resource-validation-object"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "${module.s3_bucket["processing"].s3_bucket_arn}/*"
    ]
  }
  # kms permissions
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey"
    ]
    resources = [module.kms_s3_bucket["processing"].key_arn]
  }
}

module "iam_for_transfer" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  create          = true
  use_name_prefix = true
  name            = "transfer-logging"

  trust_policy_permissions = {
    AllowTransferService = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["transfer.amazonaws.com"]
      }]
    }
  }

  policies = {
    transfer_logging = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  }

  tags = local.tags
}