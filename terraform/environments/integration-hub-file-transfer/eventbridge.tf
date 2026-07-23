module "eventbridge_default_bus" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.0"

  bus_name                   = "default"
  create_bus                 = false
  create_log_delivery        = false
  create_log_delivery_source = false
  append_rule_postfix        = false
  create_role                = false

  rules = local.eventbridge_default_bus_rules

    targets = local.eventbridge_default_bus_targets

  tags = local.tags
}

module "eventbridge_file_transfer_bus" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.0"

  bus_name            = local.application_name
  create_archives     = true
  append_rule_postfix = false

  attach_sfn_policy = true
  sfn_target_arns = [
    module.step_function_filereceived_workflow.state_machine_arn,
    module.step_function_filescanresultrecorded_workflow.state_machine_arn,
  ]

  rules = local.eventbridge_file_transfer_bus_rules

  targets = local.eventbridge_file_transfer_bus_targets

  archives = {
    "${local.application_name}-archive" = {
      description    = "Archive of all file transfer events"
      retention_days = local.cloudwatch_retention_days
    }
  }

  log_config = {
    include_detail = "FULL"
    level          = "INFO"
  }

  log_delivery = {
    cloudwatch_logs = {
      destination_arn = module.cloudwatch_eventbridge.cloudwatch_log_group_arn
    }
  }

  tags = local.tags
}