resource "aws_sqs_queue" "this" {
  for_each = var.sqs_queues

  name                    = each.key
  sqs_managed_sse_enabled = true

  tags = merge(local.tags, {
    Name = each.key
  })
}

data "aws_iam_policy_document" "sqs_queues" {
  for_each = var.sqs_queues
  dynamic "statement" {
    for_each = each.value.policy
    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = [aws_sqs_queue.this[each.key].arn]
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

resource "aws_sqs_queue_policy" "this" {
  for_each  = var.sqs_queues
  policy    = data.aws_iam_policy_document.sqs_queues[each.key].json
  queue_url = aws_sqs_queue.this[each.key].url
}
