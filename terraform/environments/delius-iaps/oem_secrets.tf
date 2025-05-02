data "aws_iam_policy_document" "OracleEnterpriseManagementSecretsPolicyDocument" {
  statement {
    sid    = "OracleEnterpriseManagementSecretsPolicyDocument"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
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

data "aws_secretsmanager_secret_version" "oem_agent_password" {
  provider = aws.hmpps-oem
  secret_id = "arn:aws:secretsmanager:eu-west-2:${local.oem_account_id}:secret:/oracle/oem/shared-passwords"
}

locals {
  oem_agent_password = jsondecode(data.aws_secretsmanager_secret_version.oem_agent_password.secret_string)["agentreg"]
}
