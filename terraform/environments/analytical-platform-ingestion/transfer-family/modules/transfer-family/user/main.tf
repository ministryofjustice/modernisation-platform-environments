# tflint-ignore-file: terraform_required_version, terraform_required_providers

data "aws_iam_policy_document" "this" {
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
    resources = [var.landing_bucket_kms_key]
  }
  statement {
    sid     = "AllowS3ListBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.landing_bucket}",
      "arn:aws:s3:::${var.landing_bucket}/${var.name}/*"
    ]
  }
  statement {
    sid       = "AllowS3LandingBucketObjectActions"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.landing_bucket}/${var.name}/*"]
  }
}

module "policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.44.1"

  name_prefix = "transfer-user-${var.name}"

  policy = data.aws_iam_policy_document.this.json
}

module "role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.44.1"

  create_role = true

  role_name         = "transfer-user-${var.name}"
  role_requires_mfa = false

  trusted_role_services = ["transfer.amazonaws.com"]

  custom_role_policy_arns = [module.policy.arn]
}

resource "aws_transfer_user" "this" {
  server_id      = var.transfer_server
  user_name      = var.name
  role           = module.role.iam_role_arn
  home_directory = "/${var.landing_bucket}/${var.name}"
}

resource "aws_transfer_ssh_key" "this" {
  server_id = var.transfer_server
  user_name = aws_transfer_user.this.user_name
  body      = var.ssh_key
}

module "secret" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  for_each = toset(["technical-contact", "data-contact", "target-bucket", "slack-channel"])

  name       = "transfer/sftp/${var.name}/${each.key}"
  kms_key_id = var.supplier_data_kms_key

  ignore_secret_changes = true
  secret_string         = "CHANGEME"
}
