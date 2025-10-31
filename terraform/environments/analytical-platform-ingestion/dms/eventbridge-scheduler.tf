resource "aws_scheduler_schedule" "tariff_dms_nightly_full_load" {
  name       = "tariff-dms-nightly-full-load"
  group_name = aws_scheduler_schedule_group.tariff_dms_nightly_full_load.name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(30 0 * * ? *)" # 12:30am every day, to capture submissions up till midnight for monthly reporting
  kms_key_arn         = module.cica_dms_eventscheduler_kms.key_arn

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:databasemigration:startReplicationTask"
    role_arn = module.tariff_eventbridge_dms_full_load_task_role.iam_role_arn

    input = jsonencode({
      ReplicationTaskArn       = module.cica_dms_tariff_dms_implementation.dms_full_load_task_arn
      StartReplicationTaskType = "reload-target"
    })
  }
}

resource "aws_scheduler_schedule_group" "tariff_dms_nightly_full_load" {
  name = "tariff-dms-nightly-full-load"
  tags = local.tags
}

resource "aws_scheduler_schedule" "tempus_dms_nightly_full_load" {
  for_each   = module.cica_dms_tempus_dms_implementation
  name       = "tempus-${each.key}-dms-nightly-full-load"
  group_name = aws_scheduler_schedule_group.tempus_dms_nightly_full_load.name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(30 0 * * ? *)" # 12:30am every day, to capture submissions up till midnight for monthly reporting
  kms_key_arn         = module.cica_dms_eventscheduler_kms.key_arn

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:databasemigration:startReplicationTask"
    role_arn = module.tempus_eventbridge_dms_full_load_task_role.iam_role_arn

    input = jsonencode({
      ReplicationTaskArn       = each.value.dms_full_load_task_arn
      StartReplicationTaskType = "reload-target"
    })
  }
}

resource "aws_scheduler_schedule_group" "tempus_dms_nightly_full_load" {
  name = "tempus-dms-nightly-full-load"
  tags = local.tags
}
