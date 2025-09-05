module "dms_task" {
  source = "./modules/dms"

  for_each = toset(local.is-production ? [
    "g4s_cap_dw",
    "g4s_emsys_mvp",
    "capita_alcohol_monitoring",
    "g4s_atrium",
    "civica_orca",
    "g4s_subject_history",
    "g4s_telephony",
    "g4s_atv",
    "g4s_rf_hours",
    "g4s_tasking",
    "g4s_fep",
    "g4s_emsys_tpims",
    "capita_forms_and_subject_id",
    "g4s_lcm_archive_2019",
    "g4s_lcm_archive_2020",
    "g4s_lcm_archive_2021",
    "g4s_lcm_archive_2022",
    "g4s_lcm_archive_2023",
    "g4s_lcm_archive_local_full",
    "g4s_centurion"
  ] : local.is-development ? ["test"] : [])

  database_name = each.key

  # DMS Source Endpoint Inputs
  rds_db_security_group_id = aws_security_group.db[0].id
  rds_db_server_name       = split(":", aws_db_instance.database_2022[0].endpoint)[0]
  rds_db_instance_port     = aws_db_instance.database_2022[0].port
  rds_db_username          = aws_db_instance.database_2022[0].username
  rds_db_instance_pasword  = aws_db_instance.database_2022[0].password

  # DMS Target Endpoint Inputs
  target_s3_bucket_name      = module.s3-dms-target-store-bucket.bucket.id
  ep_service_access_role_arn = aws_iam_role.dms_endpoint_role[0].arn

  # DMS Migration Task Inputs
  dms_replication_instance_arn    = aws_dms_replication_instance.dms_replication_instance[0].replication_instance_arn
  rep_task_settings_filepath      = trimspace(file("${path.module}/dms_replication_task_settings.json"))
  rep_task_table_mapping_filepath = trimspace(file("${path.module}/dms_${each.key}_task_tables_selection.json"))

  # DMS Validation Event bridge Rule
  event_bridge_rule_name           = "dms_validation_trigger_rule"
  event_bridge_role_name           = "dms_validation_trigger_role_${each.key}"
  dms_trigger_state                = "FULL_LOAD_ONLY_FINISHED"
  dms_validation_step_function_arn = module.dms_validation_step_function[0].arn

  local_tags = local.tags
}
