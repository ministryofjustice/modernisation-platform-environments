resource "aws_s3_bucket" "ospt_transfer" {
  bucket = "ospt-transfer"
}

# Policy documents
data "aws_iam_policy_document" "civica_s3_read_write_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.ospt_transfer.arn,
      "${aws_s3_bucket.ospt_transfer.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "node4_s3_read_write_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.ospt_transfer.arn,
      "${aws_s3_bucket.ospt_transfer.arn}/*"
    ]
  }
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [
      aws_secretsmanager_secret.s3_user_secret.arn
    ]
  }
}

# Policies
resource "aws_iam_policy" "civica_s3_access" {
  name        = "CivicaS3Access"
  description = "Provides read/write access to the ospt-transfer bucket"
  policy      = data.aws_iam_policy_document.civica_s3_read_write_policy.json
}

resource "aws_iam_policy" "node4_s3_access" {
  name        = "Node4S3Access"
  description = "Provides read/write access to the ospt-transfer bucket"
  policy      = data.aws_iam_policy_document.node4_s3_read_write_policy.json
}

# Roles that reference policies
module "collaborator_civica_s3_role" {
  source = "github.com/terraform-aws-modules/terraform-aws-iam//modules/iam-assumable-role?ref=de95e21a3bc51cd3a44b3b95a4c2f61000649ebb"

  trusted_role_arns = [
    data.aws_ssm_parameter.modernisation_platform_account_id.value
  ]

  create_role       = true
  role_name         = "civica-role"
  role_requires_mfa = true

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    aws_iam_policy.civica_s3_access.arn
  ]
  number_of_custom_role_policy_arns = 2
}

module "collaborator_node4_s3_role" {
  source = "github.com/terraform-aws-modules/terraform-aws-iam//modules/iam-assumable-role?ref=de95e21a3bc51cd3a44b3b95a4c2f61000649ebb"

  trusted_role_arns = [
    data.aws_ssm_parameter.modernisation_platform_account_id.value
  ]

  create_role       = true
  role_name         = "node4-role"
  role_requires_mfa = true

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    aws_iam_policy.node4_s3_access.arn
  ]
  number_of_custom_role_policy_arns = 2
}