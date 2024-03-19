resource "aws_iam_role" "mp_migration_role" {
  name = "mp_migration_role"
  # assumable by datasync
  assume_role_policy = data.aws_iam_policy_document.mp_migration_role_assume.json
}

data "aws_iam_policy_document" "mp_migration_role_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "mp_migration_role_policy_kms" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["arn:aws:kms:eu-west-2:479759138745:key/98e4de43-75d9-46d1-835e-99e3a2a48bd3"]
  }
}

resource "aws_iam_policy" "mp_migration_role_policy_kms" {
  name        = "mp_migration_role_policy_kms"
  description = "Policy for migration role"
  policy      = data.aws_iam_policy_document.mp_migration_role_policy_kms.json
}

resource "aws_iam_role_policy_attachment" "mp_migration_role_policy_kms" {
  role       = aws_iam_role.mp_migration_role.name
  policy_arn = aws_iam_policy.mp_migration_role_policy_kms.arn
}
