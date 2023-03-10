locals {
  iam_policies = merge(local.s3_buckets_iam_policies, var.iam_policies)
}

data "aws_iam_policy_document" "this" {
  # for_each workaround as iam_policies may sometimes contain sensitive values
  for_each = nonsensitive(sensitive(toset(keys(local.iam_policies))))

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
  # There's a weird issue where args can flip between sensitive and non-sensitive
  # value seen in nomis-data-hub accounts only.  Hence the nonsensitive workaround
  # here.  Looks like a bug so try removing at some point in future.
  for_each = nonsensitive(sensitive(toset(keys(local.iam_policies))))

  name        = each.key
  path        = nonsensitive(sensitive(local.iam_policies[each.key].path))
  description = nonsensitive(sensitive(local.iam_policies[each.key].description))
  policy      = data.aws_iam_policy_document.this[each.key].json

  tags = merge(local.tags, {
    Name = each.key
  })
}
