resource "aws_kms_key" "nomis-cmk" {
  description             = "Nomis Managed Key for AMI Sharing"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.shared_image_builder_cmk_policy.json
}

resource "aws_kms_alias" "nomis-key" {
  name          = "alias/nomis-image-builder"
  target_key_id = aws_kms_key.nomis-cmk.key_id
}

data "aws_iam_policy_document" "shared_image_builder_cmk_policy" {
  statement {
    effect = "Allow"
    actions = ["kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:ReEncryptFrom",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    "kms:CreateGrant"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:root",
      "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:root"]
    }
  }
}
