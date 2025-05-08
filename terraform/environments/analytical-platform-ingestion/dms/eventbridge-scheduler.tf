locals {
  # We stagger these jobs as they share compute resource
  # We want all these to be finished by the time the `Deploy dbt prod daily` job starts at ~4am
  # All jobs need to start post-midnight to make sure any entries from the previous day are used
  cron_timings = {
    tempus = {
      SPPFinishedJobs = {
        cron_string = "cron(0 3 * * ? *)" # 3:00am every day
        replication_task_arn = module.cica_dms_tempus_dms_implementation["SPPFinishedJobs"].dms_full_load_task_arn
      }
      SPPProcessPlatform = {
        cron_string = "cron(0 2 * * ? *)" # 2am every day
        replication_task_arn = module.cica_dms_tempus_dms_implementation["SPPProcessPlatform"].dms_full_load_task_arn
      }
      CaseWork = {
        cron_string = "cron(0 1 * * ? *)" # 1:00am every day
        replication_task_arn = module.cica_dms_tempus_dms_implementation["CaseWork"].dms_full_load_task_arn
      }
    }
    tariff = {
      cron_string = "cron(10 0 * * ? *)" # 12:10am every day
      replication_task_arn = module.cica_dms_tariff_dms_implementation.dms_full_load_task_arn
    }
  }
}

resource "aws_scheduler_schedule" "tariff_dms_nightly_full_load" {
  name       = "tariff-dms-nightly-full-load"
  group_name = aws_scheduler_schedule_group.tariff_dms_nightly_full_load.name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = local.cron_timings.tariff.cron_string
  kms_key_arn         = module.cica_dms_eventscheduler_kms.key_arn

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:databasemigration:startReplicationTask"
    role_arn = module.tariff_eventbridge_dms_full_load_task_role.iam_role_arn

    input = jsonencode({
      ReplicationTaskArn       = local.cron_timings.tariff.replication_task_arn
      StartReplicationTaskType = "reload-target"
    })
  }
}

resource "aws_scheduler_schedule_group" "tariff_dms_nightly_full_load" {
  name = "tariff-dms-nightly-full-load"
  tags = local.tags
}

resource "aws_scheduler_schedule" "tempus_dms_nightly_full_load" {
  for_each   = local.cron_timings.tempus
  name       = "tempus-${each.key}-dms-nightly-full-load"
  group_name = aws_scheduler_schedule_group.tempus_dms_nightly_full_load.name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = each.value.cron_string
  kms_key_arn         = module.cica_dms_eventscheduler_kms.key_arn

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:databasemigration:startReplicationTask"
    role_arn = module.tempus_eventbridge_dms_full_load_task_role.iam_role_arn

    input = jsonencode({
      ReplicationTaskArn       = each.value.replication_task_arn
      StartReplicationTaskType = "reload-target"
    })
  }
}

resource "aws_scheduler_schedule_group" "tempus_dms_nightly_full_load" {
  name = "tempus-dms-nightly-full-load"
  tags = local.tags
}
