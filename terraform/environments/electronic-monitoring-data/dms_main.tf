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
    "LCM_ARCHIVE_2019",
    "LCM_ARCHIVE_2020",
    "LCM_ARCHIVE_2021",
    "LCM_ARCHIVE_2022",
    "LCM_ARCHIVE_2023",
    "lcm_archive_local_full"
  ] : ["test"])

  database_name = each.key

  # DMS Source Endpoint Inputs
  rds_db_security_group_id = aws_security_group.db.id
  rds_db_server_name       = split(":", aws_db_instance.database_2022.endpoint)[0]
  rds_db_instance_port     = aws_db_instance.database_2022.port
  rds_db_username          = aws_db_instance.database_2022.username
  rds_db_instance_pasword  = aws_db_instance.database_2022.password

  # DMS Target Endpoint Inputs
  target_s3_bucket_name      = module.s3-dms-target-store-bucket.bucket.id
  ep_service_access_role_arn = aws_iam_role.dms_endpoint_role.arn

  # DMS Migration Task Inputs
  dms_replication_instance_arn    = aws_dms_replication_instance.dms_replication_instance.replication_instance_arn
  rep_task_settings_filepath      = trimspace(file("${path.module}/dms_replication_task_settings.json"))
  rep_task_table_mapping_filepath = trimspace(file("${path.module}/dms_${each.key}_task_tables_selection.json"))

  local_tags = local.tags
}
