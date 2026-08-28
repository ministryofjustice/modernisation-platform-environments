module "sns_pagerduty_high_priority" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.1"

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
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.1"

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
