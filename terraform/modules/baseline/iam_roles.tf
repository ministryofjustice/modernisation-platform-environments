locals {

  # flatten attachments
  iam_role_policy_attachments_list = flatten([
    for role_name, role_value in var.iam_roles : [
      for policy_attachment in role_value.policy_attachments : {
        role   = role_name
        policy = policy_attachment
      }
    ]
  ])

  iam_role_policy_attachments = { for item in local.iam_role_policy_attachments_list :
    "${item.role}-${item.policy}" => {
      role   = item.role
      policy = item.policy
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  for_each = var.iam_roles

  version = "2012-10-17"
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = each.value.assume_role_policy_principals_type

      # allow account names to be specified rather than the full arn
      identifiers = [for id in each.value.assume_role_policy_principals_identifiers :
        lookup(var.environment.account_root_arns, id, null) != null ? var.environment.account_root_arns[id] : id
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = var.iam_roles

  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json

  tags = merge(local.tags, {
    Name = "each.key"
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.iam_role_policy_attachments

  policy_arn = lookup(aws_iam_policy.this, each.value.policy, null) != null ? aws_iam_policy.this[each.value.policy].arn : each.value.policy
  role       = aws_iam_role.this[each.value.role].name
}
