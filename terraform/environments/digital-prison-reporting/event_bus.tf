
module "create_event_bus_dpd" {
  source             = "./modules/eventbridge"
  dpr_event_bus_name = local.event_bus_dpr

  tags = merge(
    local.all_tags,
    {
      dpr-name           = local.event_bus_dpr
      dpr-jira           = "DPR2-1715"
      dpr-resource-group = "Front-End"
    }
  )
}

data "aws_iam_policy_document" "dpr_event_bus_write_events_policy" {
  statement {
    sid    = "WriteEvents"
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]
    resources = [
      module.create_event_bus_dpd.event_bus_arn
    ]
  }
}

resource "aws_iam_policy" "dpr_event_bus_write_events_policy" {
  name        = "${local.project}-dpr_event_bus_write_events_policy"
  description = "Allows sending events to custom dpr event bus"
  policy      = data.aws_iam_policy_document.dpr_event_bus_write_events_policy.json
}