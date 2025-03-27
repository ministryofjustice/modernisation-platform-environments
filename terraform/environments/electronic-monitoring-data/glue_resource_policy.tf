## Glue DB Default Policy
resource "aws_glue_resource_policy" "glue_policy" {
  policy        = data.aws_iam_policy_document.glue-policy-data.json
  enable_hybrid = "TRUE"
}

data "aws_iam_policy_document" "glue-policy-data" {
  statement {
    actions   = ["glue:*"]
    resources = ["arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:*"]
    principals {
      identifiers = [local.environment_management.account_ids["analytical-platform-data-production"]]
      type        = "AWS"
    }
  }

  statement {
    # Required for cross-account sharing via LakeFormation if producer has existing Glue policy
    # ref: https://docs.aws.amazon.com/lake-formation/latest/dg/hybrid-cross-account.html
    effect = "Allow"

    actions = [
      "glue:ShareResource"
    ]

    principals {
      type        = "Service"
      identifiers = ["ram.amazonaws.com"]
    }
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/*/*",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog"
    ]
  }
}
