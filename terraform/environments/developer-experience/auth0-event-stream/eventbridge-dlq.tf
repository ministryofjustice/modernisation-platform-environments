module "eventbridge_dlq" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-sqs.git?ref=v5.2.2" # v5.2.2

  name                    = "${local.component_name}-dlq"
  sqs_managed_sse_enabled = true

  create_queue_policy = true
  queue_policy_statements = {
    EventBridgeSendMessage = {
      actions = ["sqs:SendMessage"]
      principals = [
        {
          type        = "Service"
          identifiers = ["events.amazonaws.com"]
        },
      ]
      condition = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        },
      ]
    }
  }
}
