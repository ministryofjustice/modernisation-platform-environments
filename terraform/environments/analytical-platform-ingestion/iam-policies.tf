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
  version = "5.44.1"

  name_prefix = "transfer-server"

  policy = data.aws_iam_policy_document.transfer_server.json
}

data "aws_iam_policy_document" "datasync" {
  statement {
    sid    = "AllowS3BucketActions"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [
      for item in local.environment_configuration.datasync_target_buckets : "arn:aws:s3:::${item}"
    ]
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
    resources = [
      for item in local.environment_configuration.datasync_target_buckets : "arn:aws:s3:::${item}"
    ]
  }
}

module "datasync_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.44.1"

  name_prefix = "datasync"

  policy = data.aws_iam_policy_document.datasync.json
}
