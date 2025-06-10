data "aws_iam_policy_document" "secrets_manager" {
  statement {
    sid = "SecretPermissions"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.ad_admin_password.arn
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

data "aws_iam_policy_document" "ec2_describe" {
  statement {
    sid = "EC2DescribePermissions"
    actions = [
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_describe" {
  name        = "${var.env_name}-ec2-describe-instances"
  path        = "/"
  description = "Allow ec2 instance to describe instances"
  policy      = data.aws_iam_policy_document.ec2_describe.json

  tags = var.tags
}
