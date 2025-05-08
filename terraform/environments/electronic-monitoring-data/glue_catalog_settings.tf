resource "aws_glue_resource_policy" "standard_policy" {
  policy = data.aws_iam_policy_document.glue-policy.json
}

data "aws_iam_policy_document" "glue-policy" {
    statement {
      effect = "Allow"
      principals {
        type = "AWS"
        identifiers = ["arn:aws:iam::${local.environment_management["analytical-platform-data-production"]}:root"]
      }
      actions = ["glue:*"]
      resources = [
        "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*",
        "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
        "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog"
      ]
    }
}