data "aws_iam_policy_document" "delivery" {
  for_each = local.push_to_s3_entries

  statement {
    sid    = "WriteConfiguredDestination"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${each.value.action.push_to_s3.bucket_id}/${each.value.action.push_to_s3.destination_prefix}*",
    ]
  }

  statement {
    sid    = "EncryptConfiguredDestination"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
    ]
    resources = [each.value.action.push_to_s3.kms_key_arn]
  }
}

module "iam_policy_delivery" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.0"

  for_each = local.push_to_s3_entries

  name        = "ihft-${local.environment}-push-to-s3-${each.key}"
  description = "Deliver one configured Integration Hub prefix to its S3 destination"
  policy      = data.aws_iam_policy_document.delivery[each.key].json

  tags = local.tags
}

module "iam_role_delivery" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.0"

  for_each = local.push_to_s3_entries

  create          = true
  use_name_prefix = false
  name            = "ihft-${local.environment}-push-to-s3-${each.key}"

  trust_policy_permissions = {
    AllowPushToS3Lambda = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.lambda_role_name}"]
      }]
    }
  }

  policies = {
    delivery = module.iam_policy_delivery[each.key].arn
  }

  tags = local.tags
}