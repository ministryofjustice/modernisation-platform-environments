##
# Create password for AD root admin
##
resource "random_password" "ad_password" {
  length  = 30
  lower   = true
  upper   = true
  numeric = true
  special = true
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "ad_password" {
  #checkov:skip=CKV_AWS_149
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  name                    = "${var.networking[0].application}-ad-password"
  recovery_window_in_days = 0
  tags = merge(
    local.tags,
    {
      Name = "${var.networking[0].application}-ad-password"
    },
  )
}

data "aws_secretsmanager_secret_version" "ad_password" {
  secret_id = aws_secretsmanager_secret.ad_password.id
}

resource "random_password" "dbsnmp_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "dbsnmp_password" {
  name                    = "/oracle/database/IAPS/shared-passwords"
  description             = "DBSNMP password for IAPS database"
  recovery_window_in_days = 7

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "dbsnmp_password" {
  secret_id     = aws_secretsmanager_secret.dbsnmp_password.id
  secret_string = random_password.dbsnmp_password.result
}

data "aws_secretsmanager_secret_version" "oem_shared_secrets" {
  provider = aws.shared_secrets
  secret_id = "arn:aws:secretsmanager:eu-west-2:${local.oem_account_id}:secret:/oracle/oem/shared-passwords"
}

locals {
  oem_shared_secrets = jsondecode(data.aws_secretsmanager_secret_version.oem_shared_secrets.secret_string)
}

data "aws_iam_policy_document" "dbsnmp_secret_policy" {
  statement {
    sid    = "AllowHMPPSOEMAccessToDBSNMPSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    principals {
      type        = "AWS"
      identifiers = local.oem_shared_secrets.oem_share_secret_principal_ids[local.environment]
    }
    resources = [
      aws_secretsmanager_secret.dbsnmp_password.arn,
    ]
  }
}

resource "aws_secretsmanager_secret_policy" "dbsnmp_secret_policy" {
  secret_arn = aws_secretsmanager_secret.dbsnmp_password.arn
  policy     = data.aws_iam_policy_document.dbsnmp_secret_policy.json
}
