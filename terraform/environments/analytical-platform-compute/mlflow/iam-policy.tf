data "aws_iam_policy_document" "mlflow" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = [module.mlflow_s3_kms.key_arn]
  }
  statement {
    sid     = "AllowS3List"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      module.mlflow_bucket.s3_bucket_arn,
      "arn:aws:s3:::${local.environment_configuration.mlflow_s3_bucket_name}"
    ]
  }
  statement {
    sid    = "AllowS3Write"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.mlflow_bucket.s3_bucket_arn}/*",
      "arn:aws:s3:::${local.environment_configuration.mlflow_s3_bucket_name}/*"
    ]
  }
}

module "mlflow_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.60.0"

  name_prefix = "mlflow"

  policy = data.aws_iam_policy_document.mlflow.json

  tags = local.tags
}
