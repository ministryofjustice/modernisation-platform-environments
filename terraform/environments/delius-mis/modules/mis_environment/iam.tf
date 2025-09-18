data "aws_iam_policy_document" "secrets_manager" {
  statement {
    sid = "SecretPermissions"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.ad_admin_password.arn,
      "arn:aws:secretsmanager:*:*:secret:NDMIS_DFI_SERVICEACCOUNTS_DEV-*",
      "arn:aws:secretsmanager:*:*:secret:delius-mis-dev-oracle-mis-db-application-passwords-*",
      "arn:aws:secretsmanager:*:*:secret:delius-mis-dev-oracle-dsd-db-application-passwords-*"
    ]
  }
}

resource "aws_iam_policy" "secrets_manager" {
  name        = "${var.env_name}-read-access-to-secrets"
  path        = "/"
  description = "Allow ec2 instance to read secrets"
  policy      = data.aws_iam_policy_document.secrets_manager.json

  tags = var.tags
}

data "aws_iam_policy_document" "ec2_automation" {
  statement {
    sid = "EC2AutomationPermissions"
    actions = [
      "ec2:DescribeTags",
      "s3:GetObject",
      "s3:ListBucket",
      "kms:Decrypt",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_automation" {
  name        = "${var.env_name}-ec2-automation-instances"
  path        = "/"
  description = "Allow ec2 instance to run automation"
  policy      = data.aws_iam_policy_document.ec2_automation.json

  tags = var.tags
}
