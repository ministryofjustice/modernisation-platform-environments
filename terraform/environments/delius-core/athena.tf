data "aws_iam_policy_document" "glue-cross-account-policy" {
  statement {
    actions = [
      "glue:*",
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*"
    ]
    principals {
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids[local.audit_share_map[local.environment]]}.:root"]
      type        = "AWS"
    }
  }
}

resource "aws_glue_resource_policy" "this" {
  policy = data.aws_iam_policy_document.glue-cross-account-policy.json
}
