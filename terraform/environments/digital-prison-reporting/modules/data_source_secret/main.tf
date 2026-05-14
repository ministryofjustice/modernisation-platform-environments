locals {
  secret_payload_placeholder = {
    db_name            = "placeholder"
    username           = "placeholder"
    user               = "placeholder"
    password           = "placeholder"
    endpoint           = "0.0.0.0"
    port               = "5432"
    heartbeat_endpoint = "0.0.0.0"
  }

  cloud_platform_aws_account_arn = "arn:aws:iam::${var.cloud_platform_aws_account_id}:root"
}

resource "aws_secretsmanager_secret" "this" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name        = "external/${var.project_id}-${var.ingestion_domain_name}-source-secrets"
  description = "Source secret for ${var.ingestion_domain_name}${var.is_cloud_platform_accessible ? " - accessible from Cloud Platform" : ""}"
  kms_key_id  = var.is_cloud_platform_accessible ? var.cloud_platform_shared_kms_key_id : null

  tags = merge(
    var.tags,
    {
      dpr-name          = "external/${var.project_id}-${var.ingestion_domain_name}-source-secrets"
      dpr-resource-type = "Secrets"
      dpr-domain        = var.ingestion_domain_name
    }
  )
}

# Gives Cloud Platform access to read and update this secret
# The IAM policy on the CP role will control which specific roles can perform each action
# See https://dsdmoj.atlassian.net/wiki/spaces/DPR/pages/6147506402/Datahub+Cross-Account+Secret+Sharing for notes
# on the original implementation
resource "aws_secretsmanager_secret_policy" "this" {
  for_each = var.is_cloud_platform_accessible ? { create = true } : {}

  secret_arn = aws_secretsmanager_secret.this.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudPlatformAccountToReadSecret"
        Effect = "Allow"
        Principal = {
          AWS = local.cloud_platform_aws_account_arn
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudPlatformAccountToWriteSecret"
        Effect = "Allow"
        Principal = {
          AWS = local.cloud_platform_aws_account_arn
        }
        Action = [
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode(local.secret_payload_placeholder)

  lifecycle {
    ignore_changes = [secret_string]
  }
}

data "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  version_id = aws_secretsmanager_secret_version.this.id
}
