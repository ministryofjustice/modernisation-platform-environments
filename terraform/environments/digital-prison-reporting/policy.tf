locals {
      account_id             = data.aws_caller_identity.current.account_id
      account_region         = data.aws_region.current.name
}


## Glue DB Default Policy
resource "aws_glue_resource_policy" "glue_policy" {
  policy = data.aws_iam_policy_document.glue-policy-data.json
}

data "aws_iam_policy_document" "glue-policy-data" {
  statement {
    actions = [
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateSchema",
      "glue:DeleteSchema",
      "glue:UpdateTable",
    ]
    resources = ["arn:aws:glue:${local.aws_region}:${local.aws_account_id}:*"]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
  }
}