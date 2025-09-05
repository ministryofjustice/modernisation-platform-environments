resource "aws_iam_role" "dms_validation_event_bridge_invoke_sfn_role" {
  name = "dms_validation_trigger_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]

  })
}

resource "aws_iam_role_policy" "event_bridge_invoke_sfn_policy" {
  role = aws_iam_role.dms_validation_event_bridge_invoke_sfn_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "states:StartExecution",
      ]
      Resource = module.dms_validation_step_function[0].arn
    }]
  })
}



resource "aws_cloudwatch_event_rule" "dms_task_completed" {
  name        = "dms_validation_trigger_rule"
  description = "Triggeres DMS validation Step Function"

  event_pattern = jsonencode({
    "source" : ["aws.dms"],
    "detail-type" : ["DMS Replication Task State Change"],
    "detail" : {
      "eventId" : ["DMS-EVENT-0079"],
      "eventType" : ["REPLICATION_TASK_STOPPED"]
      "detailMessage" : ["Stop Reason FULL_LOAD_ONLY_FINISHED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "dms_validation_step_function_trigger" {
  rule       = aws_cloudwatch_event_rule.dms_task_completed.name
  arn        = module.dms_validation_step_function[0].arn
  role_arn   = aws_iam_role.dms_validation_event_bridge_invoke_sfn_role.arn
  input_path = "$"
}


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

  local_tags = local.tags
}
