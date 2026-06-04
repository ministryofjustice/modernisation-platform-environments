moved {
  from = module.tariff_eventbridge_dms_full_load_task_role.aws_iam_role_policy_attachment.custom[0]
  to   = module.tariff_eventbridge_dms_full_load_task_role.aws_iam_role_policy_attachment.this["tariff_eventbridge_dms_full_load_task_policy"]
}

moved {
  from = module.tempus_eventbridge_dms_full_load_task_role.aws_iam_role_policy_attachment.custom[0]
  to   = module.tempus_eventbridge_dms_full_load_task_role.aws_iam_role_policy_attachment.this["tempus_eventbridge_dms_full_load_task_policy"]
}