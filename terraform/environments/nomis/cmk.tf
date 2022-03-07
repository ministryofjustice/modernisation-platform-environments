resource "aws_kms_key" "nomis-cmk" {
  description             = "Nomis Managed Key for AMI Sharing"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.shared_image_builder_cmk_policy
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

# {
#     "Version": "2012-10-17",
#     "Statement": [
# {
#     "Sid": "Allow administration of the key",
#                   "Effect": "Allow",
#                   "Principal": { "AWS": "arn:aws:iam::612659970365:root" },
#                   "Action": [
#                       "kms:Create*",
#                       "kms:Describe*",
#                       "kms:Enable*",
#                       "kms:List*",
#                       "kms:Put*",
#                       "kms:Update*",
#                       "kms:Revoke*",
#                       "kms:Disable*",
#                       "kms:Get*",
#                       "kms:Delete*",
#                       "kms:ScheduleKeyDeletion",
#                       "kms:CancelKeyDeletion"
#                   ],
#                   "Resource": "*"
# },{
#     "Sid": "Allow external account 374269020027 use of the CMK",
#     "Effect": "Allow",
#     "Principal": {
#         "AWS": [
#             "arn:aws:iam::374269020027:root",
#             "arn:aws:iam::612659970365:root"
#         ]
#     },
#     "Action": [
#         "kms:Encrypt",
#         "kms:Decrypt",
#         "kms:ReEncrypt*",
#         "kms:ReEncryptFrom",
#         "kms:GenerateDataKey*",
#         "kms:DescribeKey"
#     ],
#     "Resource": "*"
# },{
#     "Sid": "Allow attachment of persistent resources in external account 374269020027",
#     "Effect": "Allow",
#     "Principal": {
#         "AWS": [
#             "arn:aws:iam::374269020027:root",
#             "arn:aws:iam::612659970365:root"
#         ]
#     },
#     "Action": [
#         "kms:CreateGrant"
#     ],
#     "Resource": "*"
#  }
# ]
# }