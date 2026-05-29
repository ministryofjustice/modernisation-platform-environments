# This file is used to import the existing resource to  Terraform state.Will be deleted after the import is complete and the state file is updated.


# moved block for iam policy attachment v5 to v6 upgrade
moved {
  from = module.lake_formation_share_role.aws_iam_role_policy_attachment.custom[0]
  to   = module.lake_formation_share_role.aws_iam_role_policy_attachment.this["lakeformation_share_policy"]
}

moved {
  from = module.lake_formation_share_role.aws_iam_role_policy_attachment.custom[1]
  to   = module.lake_formation_share_role.aws_iam_role_policy_attachment.this["aws_lakeformation_policy"]
}