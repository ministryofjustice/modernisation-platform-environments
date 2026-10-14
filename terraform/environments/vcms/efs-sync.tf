
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

    resources = [aws_efs_file_system.vcms.arn]
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

    resources = [aws_efs_file_system.vcms.arn]

    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }
}

resource "aws_efs_file_system_policy" "destination_replication" {
  file_system_id = aws_efs_file_system.vcms.id
  policy         = data.aws_iam_policy_document.destination_efs_replication_policy.json
}