resource "aws_datasync_task" "opg_investigations" {
  name                     = "opg-investigations"
  source_location_arn      = aws_datasync_location_smb.opg_investigations.arn
  destination_location_arn = aws_datasync_location_s3.opg_investigations.arn
  cloudwatch_log_group_arn = module.datasync_task_logs.cloudwatch_log_group_arn

  options {
    gid               = "NONE"
    uid               = "NONE"
    posix_permissions = "NONE"
    log_level         = "TRANSFER"
    verify_mode       = "ONLY_FILES_TRANSFERRED"
  }

  task_report_config {
    report_overrides {}
    report_level         = "ERRORS_ONLY"
    output_type          = "STANDARD"
    s3_object_versioning = "INCLUDE"

    s3_destination {
      bucket_access_role_arn = module.datasync_iam_role.iam_role_arn
      s3_bucket_arn          = module.datasync_opg_investigations_bucket.s3_bucket_arn
    }
  }

  schedule {
    schedule_expression = "cron(0 23 ? * THU *)"
  }

  tags = local.tags
}
