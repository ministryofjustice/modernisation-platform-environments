module "s3_landing_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases               = ["s3/landing"]
  description           = "Family SFTP Server, Landing S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "s3_processed_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases               = ["s3/processed"]
  description           = "Family SFTP Server, Processed S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "s3_quarantine_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases               = ["s3/quarantine"]
  description           = "Family SFTP Server, Quarantine S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "s3_definitions_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases               = ["s3/definitions"]
  description           = "Ingestion Scanning ClamAV S3 KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}

data "aws_iam_policy_document" "s3_bold_egress_kms_policy" {
  statement {
    sid     = "Default"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
  statement {
    sid = "AllowAnalyticalPlatformDataEngineeringProduction"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["*"]
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::593291632749:role/mojap-data-production-bold-egress-${local.environment}"]
    }
  }
}

module "s3_bold_egress_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases     = ["s3/bold_egress"]
  description = "Used in the Bold Egress Solution"
  policy      = data.aws_iam_policy_document.s3_bold_egress_kms_policy.json

  deletion_window_in_days = 7
}

module "sns_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases               = ["sns/notify"]
  description           = "Key for SNS notifications"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "govuk_notify_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases               = ["secretsmanager/govuk-notify"]
  description           = "Key for GOV.UK Notify data"
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "supplier_data_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases               = ["secretsmanager/supplier-data"]
  description           = "Key for SFTP supplier data"
  enable_default_policy = true

  deletion_window_in_days = 7
}
