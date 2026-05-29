# This file is used to import the existing resource to  Terraform state.Will be deleted after the import is complete and the state file is updated.

# analytical_platform_data_eng_dba_service_role
moved {
  from = module.analytical_platform_data_eng_dba_service_role.aws_iam_role_policy_attachment.custom[0]
  to   = module.analytical_platform_data_eng_dba_service_role.aws_iam_role_policy_attachment.this["lakeformation_share_policy"]
}

moved {
  from = module.analytical_platform_data_eng_dba_service_role.aws_iam_role_policy_attachment.custom[1]
  to   = module.analytical_platform_data_eng_dba_service_role.aws_iam_role_policy_attachment.this["aws_lakeformation_policy"]
}

# copy_apdp_cadet_metadata_to_compute_assumable_role
moved {
  from = module.copy_apdp_cadet_metadata_to_compute_assumable_role.aws_iam_role_policy_attachment.custom[0]
  to   = module.copy_apdp_cadet_metadata_to_compute_assumable_role.aws_iam_role_policy_attachment.this["copy_apdp_cadet_metadata_to_compute_policy"]
}

# lake_formation_to_data_production_mojap_derived_tables_role
moved {
  from = module.lake_formation_to_data_production_mojap_derived_tables_role.aws_iam_role_policy_attachment.custom[0]
  to   = module.lake_formation_to_data_production_mojap_derived_tables_role.aws_iam_role_policy_attachment.this["mojap_derived_bucket_lake_formation_policy"]
}


# analytical_platform_control_panel_service_role
moved {
  from = module.analytical_platform_control_panel_service_role.aws_iam_role_policy_attachment.custom[0]
  to   = module.analytical_platform_control_panel_service_role.aws_iam_role_policy_attachment.this["lakeformation_share_policy"]
}

moved {
  from = module.analytical_platform_control_panel_service_role.aws_iam_role_policy_attachment.custom[1]
  to   = module.analytical_platform_control_panel_service_role.aws_iam_role_policy_attachment.this["aws_lakeformation_policy"]
}
