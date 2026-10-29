locals {
  ingestion_registry_enabled = local.is-development
}

data "aws_iam_policy_document" "ingestion_registry_kms" {
  count = local.ingestion_registry_enabled ? 1 : 0

  statement {
    sid    = "EnableAccountIAMPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "ingestion_registry" {
  count = local.ingestion_registry_enabled ? 1 : 0

  description             = "Encryption key for the shared Ingestion Registry"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.ingestion_registry_kms[0].json

  tags = local.tags
}

resource "aws_kms_alias" "ingestion_registry" {
  count = local.ingestion_registry_enabled ? 1 : 0

  name          = "alias/${local.application_name}-${local.environment}-ingestion-registry"
  target_key_id = aws_kms_key.ingestion_registry[0].key_id
}

module "ingestion_registry" {
  count = local.ingestion_registry_enabled ? 1 : 0

  source = "github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/database-migration-service/modules/ingestion-registry?ref=e3db8e4f0d7c1f8cd6ef7586692760d3c5ae9eff"

  name        = "${local.application_name}-${local.environment}-ingestion-registry"
  kms_key_arn = aws_kms_key.ingestion_registry[0].arn

  tags = local.tags
}
