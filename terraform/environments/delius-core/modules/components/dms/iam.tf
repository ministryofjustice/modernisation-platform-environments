
# new IAM role OEM setup to allow DMS to access secrets manager and kms keys
resource "aws_iam_role" "DMSSecretsManagerAccessRole" {
  name = "DMSSecretsManagerAccessRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
         "Service": ["dms.eu-west-2.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dms_allow_kms_keys_access" {
  role       = aws_iam_role.DMSSecretsManagerAccessRole.name
  policy_arn = var.business_unit_kms_key_access_arn
}

data "aws_iam_policy_document" "DMSSecretsManagerAccessRolePolicyDocument" {
  statement {
    sid    = "DMSSecretsManagerAccessRolePolicyDocument"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:*:*:secret:dms_audit_endpoint_source-*",
      "arn:aws:secretsmanager:*:*:secret:dms_audit_endpoint_target-*",
      "arn:aws:secretsmanager:*:${local.delius_account_id}:secret:delius-core-${var.env_name}-oracle-db-application-passwords*"

    ]
  }
}

resource "aws_iam_policy" "DMSSecretsManagerAccessRolePolicy" {
  name   = "DMSSecretsManagerAccessRolePolicy"
  policy = data.aws_iam_policy_document.DMSSecretsManagerAccessRolePolicyDocument.json
}

resource "aws_iam_role_policy_attachment" "DMSSecretsManagerAccessRolePolicy" {
  role       = aws_iam_role.DMSSecretsManagerAccessRole.name
  policy_arn = aws_iam_policy.DMSSecretsManagerAccessRolePolicy.arn
}