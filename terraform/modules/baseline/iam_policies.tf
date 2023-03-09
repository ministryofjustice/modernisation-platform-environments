locals {
  iam_policies = merge(local.s3_buckets_iam_policies, var.iam_policies)
}

data "aws_iam_policy_document" "this" {
  # for_each keys only to avoid sensitive value for_each error
  for_each = toset(keys(local.iam_policies))

  dynamic "statement" {
    for_each = local.iam_policies[each.key].statements

    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources

      dynamic "principals" {
        for_each = statement.value.principals != null ? [statement.value.principals] : []
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = statement.value.conditions

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_policy" "this" {
  # for_each keys only to avoid sensitive value for_each error
  for_each = toset(keys(local.iam_policies))

  name        = each.key
  path        = local.iam_policies[each.key].path
  description = local.iam_policies[each.key].description
  policy      = data.aws_iam_policy_document.this[each.key].json

  tags = merge(local.tags, {
    Name = each.key
  })
}
