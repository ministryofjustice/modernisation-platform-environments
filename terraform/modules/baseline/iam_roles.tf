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

  dynamic "statement" {
    for_each = each.value.assume_role_policy
    content {
      effect  = statement.value.effect
      actions = statement.value.actions
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
          values   = [for value in condition.value.values : try(aws_ssm_parameter.fixed[value].value, value)]
        }
      }
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = var.iam_roles

  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json

  tags = merge(local.tags, each.value.tags, {
    Name = each.key
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.iam_role_policy_attachments

  policy_arn = lookup(aws_iam_policy.this, each.value.policy, null) != null ? aws_iam_policy.this[each.value.policy].arn : each.value.policy
  role       = aws_iam_role.this[each.value.role].name
}

resource "aws_iam_service_linked_role" "this" {
  for_each = var.iam_service_linked_roles

  aws_service_name = each.key
  custom_suffix    = each.value.custom_suffix
  description      = each.value.description
  tags = merge(local.tags, each.value.tags, {
    Name = each.key
  })
}
