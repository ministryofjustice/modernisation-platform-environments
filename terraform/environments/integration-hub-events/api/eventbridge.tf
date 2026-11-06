module "eventbridge_bus" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.2"

  bus_name            = local.application_name
  create_archives     = true
  append_rule_postfix = false

  # Subscribers add their own rules and targets.
  create_rules   = false
  create_targets = false

  archives = {
    "${local.application_name}-archive" = {
      description    = "Archive of all events published to the Integration Hub events bus"
      retention_days = 30
    }
  }

  tags = local.tags
}
