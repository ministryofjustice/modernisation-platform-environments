module "sns_pagerduty_high_priority" {
  source  = "terraform-aws-modules/sns/aws"
  version = "6.2.0"

  name = "pagerduty-high-priority"
  subscriptions = {
    pagerduty = {
      protocol = "https"
      endpoint = "https://events.pagerduty.com/integration/${local.pagerduty_integration_keys["integration_hub_high_priority"]}/enqueue"
    }
  }
  topic_policy_statements = {
    allow_eventbridge_publish = {
      actions = ["sns:Publish"]
      principals = [
        {
          type        = "Service"
          identifiers = ["events.amazonaws.com"]
        }
      ]
    }
  }
}

module "sns_pagerduty_low_priority" {
  source  = "terraform-aws-modules/sns/aws"
  version = "6.2.0"

  name = "pagerduty-low-priority"
  subscriptions = {
    pagerduty = {
      protocol = "https"
      endpoint = "https://events.pagerduty.com/integration/${local.pagerduty_integration_keys["integration_hub_low_priority"]}/enqueue"
    }
  }
  topic_policy_statements = {
    allow_eventbridge_publish = {
      actions = ["sns:Publish"]
      principals = [
        {
          type        = "Service"
          identifiers = ["events.amazonaws.com"]
        }
      ]
    }
  }
}
