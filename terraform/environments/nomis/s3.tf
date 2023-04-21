#  Audit Archive dumps bucket
data "aws_iam_policy_document" "nomis-all-environments-access" {
  statement {
    sid = "all-nomis-environments-access-for-archiving"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"

    ]

    resources = [
      "arn:aws:s3:::nomis-audit-archives*",
      "arn:aws:s3:::nomis-audit-archives*/*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["nomis-development"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["nomis-test"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["nomis-preproduction"]}:root",
        "arn:aws:iam::${local.environment_management.account_ids["nomis-production"]}:root"
      ]
    }
  }
}
