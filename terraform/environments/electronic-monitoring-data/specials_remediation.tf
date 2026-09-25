locals {
  specials_remediation_prefix = "specials-remediation/${local.environment_shorthand}"
}

resource "aws_iam_role" "specials_remediation" {
  name               = "specials_remediation_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "specials_remediation" {
  statement {
    sid    = "SpecialsRemediationObjectAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "${module.s3-logging-bucket.bucket.arn}/${local.specials_remediation_prefix}/*",
    ]
  }

  statement {
    sid    = "SpecialsRemediationListAccess"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      module.s3-logging-bucket.bucket.arn,
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "${local.specials_remediation_prefix}/*",
      ]
    }
  }
}

resource "aws_iam_policy" "specials_remediation" {
  name   = "specials_remediation_lambda_policy"
  policy = data.aws_iam_policy_document.specials_remediation.json
}

resource "aws_iam_role_policy_attachment" "specials_remediation" {
  role       = aws_iam_role.specials_remediation.name
  policy_arn = aws_iam_policy.specials_remediation.arn
}