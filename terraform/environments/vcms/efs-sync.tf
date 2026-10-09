
data "aws_iam_policy_document" "destination_efs_replication_policy" {
  statement {
    sid    = "AllowSourceAccountReplicationActions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${aws_ssm_parameter.legacy_account_id.value}:root"]
    }

    actions = [
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:CreateReplicationConfiguration",
      "elasticfilesystem:DescribeReplicationConfigurations",
      "elasticfilesystem:DeleteReplicationConfiguration",
      "elasticfilesystem:ReplicationWrite"
    ]

    resources = [module.efs.file_system_arn]
  }

  statement {
    sid    = "AllowClientAccessViaMountTarget"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess"
    ]

    resources = [module.efs.file_system_arn]

    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }
}

resource "aws_efs_file_system_policy" "destination_replication" {
  file_system_id = module.efs.file_system_id
  policy         = data.aws_iam_policy_document.destination_efs_replication_policy.json
}