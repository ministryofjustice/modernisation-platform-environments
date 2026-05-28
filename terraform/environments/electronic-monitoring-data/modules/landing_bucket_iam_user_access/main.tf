#tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user" "supplier" {
  #checkov:skip=CKV_AWS_273: "Ensure access is controlled through SSO and not AWS IAM defined users. Supplier temporary access via IAM user."
  name = "${var.local_bucket_prefix}-${var.data_feed}-${var.order_type}"
  tags = merge(
    var.local_tags,
    { order_type = var.order_type },
    { data_feed = var.data_feed }
  )
}

resource "aws_iam_user_policy" "supplier_data_access" {
  #checkov:skip=CKV_AWS_40: Used by a service user
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
  statement {
    actions = [
      "iam:ListAccessKeys"
    ]
    resources = [aws_iam_user.supplier.arn]
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "rotate_iam_keys" {
  statement {
    sid    = "IAMKeyPermissionsForUpdatingKey${var.data_feed}${var.order_type}"
    effect = "Allow"
    actions = [
      "iam:DeleteAccessKey",
      "iam:UpdateAccessKey",
      "iam:ListAccessKeys",
      "iam:CreateAccessKey"
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
      "secretsmanager:UpdateSecretVersionStage",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:PutSecretValue",
      "secretsmanager:DescribeSecret",
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

module "secrets_manager" {
  #checkov:skip=CKV_TF_1: "Module registry does not support commit hashes for versions"
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.0"

  name        = "iam-${aws_iam_user.supplier.name}"
  description = "IAM user access credentials for ${var.data_feed}-${var.order_type}"
  secret_string = jsonencode({
    key    = "placeholder_key",
    secret = "placeholder_secret"
  })
  ignore_secret_changes = true

  enable_rotation     = true
  rotation_lambda_arn = var.rotation_lambda.lambda_function_arn
  rotation_rules = {
    # Runs at 10:00 AM on the second Tuesday of Feb, May, Aug, Nov.
    schedule_expression = "cron(0 10 ? FEB,MAY,AUG,NOV TUE#2 *)"
  }

  tags = merge(
    var.local_tags,
    { order_type = var.order_type },
    { data_feed = var.data_feed }
  )
}

resource "aws_lambda_permission" "allow_secrets_invoke" {
  action        = "lambda:InvokeFunction"
  function_name = var.rotation_lambda.lambda_function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = module.secrets_manager.secret_arn
}
