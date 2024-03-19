resource "aws_iam_role" "mp_migration_role" {
  name = "mp_migration_role_${var.env_name}"
  # assumable by datasync
  assume_role_policy = data.aws_iam_policy_document.mp_migration_role_assume.json
}

data "aws_iam_policy_document" "mp_migration_role_assume" {
  statement {
    actions = ["sts:AssumeRole"]
  }
}


##############
# KMS Policy #
##############
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
  name        = "mp_migration_role_policy_kms_${var.env_name}"
  description = "Policy for migration role"
  policy      = data.aws_iam_policy_document.mp_migration_role_policy_kms.json
}

resource "aws_iam_role_policy_attachment" "mp_migration_role_policy_kms" {
  role       = aws_iam_role.mp_migration_role.name
  policy_arn = aws_iam_policy.mp_migration_role_policy_kms.arn
}

##############
# S3 Policy  #
##############

# data "aws_iam_policy_document" "mp_migration_role_policy_s3" {
#   statement {
#     actions = [
#       "s3:GetObject",
#       "s3:PutObject",
#       "s3:ListBucket",
#     ]
#     resources = [
#       "arn:aws:s3:::nextcloud-migration-${var.env_name}/*",
#       "arn:aws:s3:::sandbox-mp-migration-${var.env_name}",
#     ]
#   }
# }

# resource "aws_iam_policy" "mp_migration_role_policy_s3" {
#   name        = "mp_migration_role_policy_s3_${var.env_name}"
#   description = "Policy for migration role"
#   policy      = data.aws_iam_policy_document.mp_migration_role_policy_s3.json
# }

# resource "aws_iam_role_policy_attachment" "mp_migration_role_policy_s3" {
#   role       = aws_iam_role.mp_migration_role.name
#   policy_arn = aws_iam_policy.mp_migration_role_policy_s3.arn
# }
