resource "aws_datasync_task" "opg" {
  name                     = "opg"
  source_location_arn      = aws_datasync_location_smb.opg.arn
  destination_location_arn = aws_datasync_location_s3.opg.arn
  cloudwatch_log_group_arn = module.datasync_task_logs.cloudwatch_log_group_arn

  options {
    gid               = "NONE"
    uid               = "NONE"
    posix_permissions = "NONE"
    log_level         = "TRANSFER"
    verify_mode       = "ONLY_FILES_TRANSFERRED"
  }

  includes {
    filter_type = "SIMPLE_PATTERN"
    value       = "/ITAS/Database/ITAS Database/ITAS Database.xlsx|/ITAS/Database/ITAS Complaints Db/ITAS Complaints Database.xlsx"
  }

  task_report_config {
    report_overrides {}
    report_level         = "ERRORS_ONLY"
    output_type          = "STANDARD"
    s3_object_versioning = "INCLUDE"

    s3_destination {
      bucket_access_role_arn = module.datasync_iam_role.iam_role_arn
      s3_bucket_arn          = module.datasync_opg_bucket.s3_bucket_arn
    }
  }

  # schedule {
  #   schedule_expression = "cron(0 23 ? * THU *)"
  # }

  tags = local.tags
}
