module "dms_task" {
  source = "./modules/dms"

  for_each = toset(var.database_list)

  database_name = each.key

  # DMS Source Endpoint Inputs
  rds_db_security_group_id = aws_security_group.db.id
  rds_db_server_name       = split(":", aws_db_instance.database_2022.endpoint)[0]
  rds_db_instance_port     = aws_db_instance.database_2022.port
  rds_db_username          = aws_db_instance.database_2022.username
  rds_db_instance_pasword  = aws_db_instance.database_2022.password

  # DMS Target Endpoint Inputs
  target_s3_bucket_name      = aws_s3_bucket.dms_target_ep_s3_bucket.id
  ep_service_access_role_arn = aws_iam_role.dms-endpoint-role.arn

  # DMS Migration Task Inputs
  dms_replication_instance_arn    = aws_dms_replication_instance.dms_replication_instance.replication_instance_arn
  rep_task_settings_filepath      = trimspace(file("${path.module}/dms_replication_task_settings.json"))
  rep_task_table_mapping_filepath = trimspace(file("${path.module}/dms_rep_task_table_mappings.json"))

  local_tags = local.tags
}
