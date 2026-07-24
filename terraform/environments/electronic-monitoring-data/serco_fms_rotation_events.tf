# ------------------------------------------------------------------------------
# Serco FMS IAM key rotation completion events
# ------------------------------------------------------------------------------

locals {
  serco_fms_rotation_completion_events_enabled = local.is-development

  serco_fms_rotation_event_bus_name = "default"

  serco_fms_rotation_event_bus_arn = format(
    "arn:aws:events:%s:%s:event-bus/%s",
    data.aws_region.current.name,
    data.aws_caller_identity.current.account_id,
    local.serco_fms_rotation_event_bus_name,
  )
}

data "aws_iam_policy_document" "rotate_iam_key_eventbridge" {
  statement {
    sid    = "PublishRotationCompletionEvents"
    effect = "Allow"

    actions = [
      "events:PutEvents",
    ]

    resources = [
      local.serco_fms_rotation_event_bus_arn,
    ]
  }
}

resource "aws_iam_policy" "rotate_iam_key_eventbridge" {
  name = format(
    "rotate-iam-key-eventbridge-%s",
    local.environment_shorthand,
  )

  description = (
    "Allows the IAM key rotation Lambda to publish completion events"
  )

  policy = data.aws_iam_policy_document.rotate_iam_key_eventbridge.json
}

resource "aws_iam_role_policy_attachment" "rotate_iam_key_eventbridge" {
  role = aws_iam_role.rotate_iam_keys.name

  policy_arn = aws_iam_policy.rotate_iam_key_eventbridge.arn
}