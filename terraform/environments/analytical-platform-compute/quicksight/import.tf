moved {
  from = module.find_moj_data_quicksight_sa_assumable_role.aws_iam_role_policy_attachment.custom[0]
  to   = module.find_moj_data_quicksight_sa_assumable_role.aws_iam_role_policy_attachment.this["find_moj_data_quicksight_policy"]
}