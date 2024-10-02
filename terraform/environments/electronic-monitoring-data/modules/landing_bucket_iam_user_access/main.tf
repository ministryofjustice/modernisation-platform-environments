#checkov:skip=CKV_AWS_273 "Ensure access is controlled through SSO and not AWS IAM defined users. Supplier temporary access via IAM user."
resource "aws_iam_user" "supplier" {
  name = "${var.local_bucket_prefix}-${var.data_feed}-${var.order_type}"
  tags = merge(
    var.local_tags,
    { order_type = var.order_type },
    { data_feed = var.data_feed }
  )
}

resource "aws_iam_user_policy" "supplier_data_access" {
  name   = "put-s3-${var.data_feed}-${var.order_type}-policy"
  user   = aws_iam_user.supplier.name
  policy = data.aws_iam_policy_document.supplier_data_access.json
}

data "aws_iam_policy_document" "supplier_data_access" {
  statement {
    actions = [
      "s3:PutObject"
    ]

    resources = [
      var.landing_bucket_arn,
      "${var.landing_bucket_arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "rotate_iam_keys" {
  statement {
    sid    = "IAMKeyPermissionsForUpdatingKey${var.data_feed}${var.order_type}"
    effect = "Allow"
    actions = [
      "iam:DeleteAccessKey",
      "iam:UpdateAccessKey",
      "iam:ListAccessKeys",
      "iam:CreateAccessKeys"
    ]
    resources = [aws_iam_user.supplier.arn]
  }
  statement {
    sid    = "UpdateSecretsPermissions${var.data_feed}${var.order_type}"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecrets",
      "secretsmanager:UpdateSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [module.secrets_manager.secret_arn]
  }
}

resource "aws_iam_policy" "rotate_iam_keys" {
  name        = "rotate-iam-keys-lambda-policy-${var.data_feed}-${var.order_type}"
  description = "IAM policy for rotating iam keys for ${var.data_feed} ${var.order_type}"
  policy      = data.aws_iam_policy_document.rotate_iam_keys.json
}

resource "aws_iam_role_policy_attachment" "rotate_iam_keys" {
  role       = var.rotation_lambda_role_name
  policy_arn = aws_iam_policy.rotate_iam_keys.arn
}


resource "aws_iam_access_key" "supplier" {
  user = aws_iam_user.supplier.name
}

module "secrets_manager" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source = "terraform-aws-modules/secrets-manager/aws"

  name        = "iam-${aws_iam_user.supplier.name}"
  description = "IAM user access credentials for ${var.data_feed}-${var.order_type}"
  secret_string = jsonencode({
    key    = aws_iam_access_key.supplier.id,
    secret = aws_iam_access_key.supplier.secret
  })
  enable_rotation     = true
  rotation_lambda_arn = var.rotation_lambda_arn
  rotation_rules = {
    automatically_after_days = 84
  }
  tags = merge(
    var.local_tags,
    { order_type = var.order_type },
    { data_feed = var.data_feed }
  )
}
