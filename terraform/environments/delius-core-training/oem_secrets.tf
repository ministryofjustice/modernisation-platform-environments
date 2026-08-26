data "aws_iam_policy_document" "OracleEnterpriseManagementSecretsPolicyDocument" {
  statement {
    sid    = "OracleEnterpriseManagementSecretsPolicyDocument"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:*:*:secret:/oracle/database/EMREP/shared-*",
      "arn:aws:secretsmanager:*:*:secret:/oracle/database/*RCVCAT/shared-*",
      "arn:aws:secretsmanager:*:*:secret:/oracle/oem/shared-*"
    ]
  }
}

resource "aws_iam_policy" "OracleEnterpriseManagementSecretsPolicy" {
  name   = "OracleEnterpriseManagementSecretsPolicy"
  policy = data.aws_iam_policy_document.OracleEnterpriseManagementSecretsPolicyDocument.json
}

resource "aws_iam_role_policy_attachment" "OracleEnterpriseManagementSecretsPolicy" {
  role       = aws_iam_role.EC2OracleEnterpriseManagementSecretsRole.name
  policy_arn = aws_iam_policy.OracleEnterpriseManagementSecretsPolicy.arn
}

# new IAM role OEM setup to allow ec2s to access secrets manager and kms keys
resource "aws_iam_role" "EC2OracleEnterpriseManagementSecretsRole" {
  name = "EC2OracleEnterpriseManagementSecretsRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "ForAnyValue:ArnLike": {
          "aws:PrincipalArn": "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/instance-role-delius-*-db-*"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "allow_kms_keys_access" {
  role       = aws_iam_role.EC2OracleEnterpriseManagementSecretsRole.name
  policy_arn = aws_iam_policy.business_unit_kms_key_access.arn
}


data "aws_iam_policy_document" "business_unit_kms_key_access" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = [
      data.aws_kms_key.general_shared.arn,
    ]
  }
}

resource "aws_iam_policy" "business_unit_kms_key_access" {
  name   = "${terraform.workspace}-db-business_unit_kms_key_access_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.business_unit_kms_key_access.json
}
