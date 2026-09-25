data "aws_iam_policy_document" "mover" {
  for_each = local.hosted_pickup_entries

  statement {
    sid     = "ReadConfiguredSourceVersions"
    effect  = "Allow"
    actions = ["s3:GetObjectVersion"]
    resources = [
      "${data.aws_s3_bucket.clean.arn}/${each.value.identity}${each.value.source_prefix}*",
    ]
  }

  statement {
    sid     = "DecryptConfiguredSource"
    effect  = "Allow"
    actions = ["kms:Decrypt"]
    resources = [
      data.aws_kms_key.clean.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.eu-west-2.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        data.aws_s3_bucket.clean.arn,
        "${data.aws_s3_bucket.clean.arn}/${each.value.identity}${each.value.source_prefix}*",
      ]
    }
  }

  statement {
    sid    = "WriteConfiguredHostedDestination"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${local.hosted_bucket_names[each.key]}/${each.value.action.push_to_s3_with_hosted_pickup.destination_prefix}*",
    ]
  }

  statement {
    sid    = "EncryptConfiguredHostedDestination"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
    ]
    resources = [module.kms_hosted_pickup[each.key].key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.eu-west-2.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["arn:aws:s3:::${local.hosted_bucket_names[each.key]}"]
    }
  }
}

module "iam_role_mover" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.0"

  for_each = local.hosted_pickup_entries

  create          = true
  use_name_prefix = false
  name            = local.mover_role_names[each.key]

  trust_policy_permissions = {
    AllowHostedPickupLambda = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }]
      condition = [{
        test     = "ArnEquals"
        variable = "aws:PrincipalArn"
        values   = [local.lambda_role_arn]
      }]
    }
  }

  tags = local.tags
}

module "iam_policy_mover" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.0"

  for_each = local.hosted_pickup_entries

  name        = local.mover_role_names[each.key]
  description = "Move one configured Integration Hub prefix to its hosted pickup bucket"
  policy      = data.aws_iam_policy_document.mover[each.key].json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "mover" {
  for_each = local.hosted_pickup_entries

  role       = module.iam_role_mover[each.key].name
  policy_arn = module.iam_policy_mover[each.key].arn
}

data "aws_iam_policy_document" "customer_pickup" {
  for_each = local.hosted_pickup_entries

  statement {
    sid    = "ListHostedPickupPrefix"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:ListBucketVersions",
    ]
    resources = [
      "arn:aws:s3:::${local.hosted_bucket_names[each.key]}",
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${each.value.action.push_to_s3_with_hosted_pickup.destination_prefix}*"]
    }
  }

  statement {
    sid    = "ReadHostedPickupObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = [
      "arn:aws:s3:::${local.hosted_bucket_names[each.key]}/${each.value.action.push_to_s3_with_hosted_pickup.destination_prefix}*",
    ]
  }

  statement {
    sid    = "DecryptHostedPickupObjects"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = [module.kms_hosted_pickup[each.key].key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.eu-west-2.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["arn:aws:s3:::${local.hosted_bucket_names[each.key]}"]
    }
  }
}

module "iam_role_customer_pickup" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.0"

  for_each = local.hosted_pickup_entries

  create          = true
  use_name_prefix = false
  name            = local.customer_pickup_role_names[each.key]
  description     = "Read files from one hosted pickup bucket"

  # Keep the role unusable until the customer principal and trust conditions are agreed.
  trust_policy_permissions = {
    DenyAssumptionUntilCustomerTrustIsConfigured = {
      effect  = "Deny"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "AWS"
        identifiers = ["*"]
      }]
    }
  }

  tags = local.tags
}

module "iam_policy_customer_pickup" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.0"

  for_each = local.hosted_pickup_entries

  name        = local.customer_pickup_role_names[each.key]
  description = "Read files from one hosted pickup bucket"
  policy      = data.aws_iam_policy_document.customer_pickup[each.key].json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "customer_pickup" {
  for_each = local.hosted_pickup_entries

  role       = module.iam_role_customer_pickup[each.key].name
  policy_arn = module.iam_policy_customer_pickup[each.key].arn
}