resource "aws_datasync_task" "opg" {

  count = local.environment == "production" ? 1 : 0

  name                     = "opg"
  source_location_arn      = aws_datasync_location_smb.opg.arn
  destination_location_arn = aws_datasync_location_s3.opg.arn
  cloudwatch_log_group_arn = module.datasync_task_logs.cloudwatch_log_group_arn

  options {
    gid               = "NONE"
    uid               = "NONE"
    posix_permissions = "NONE"
    log_level         = "TRANSFER"
    transfer_mode     = "CHANGED"
    verify_mode       = "NONE"
  }

  includes {
    filter_type = "SIMPLE_PATTERN"
    value       = data.aws_secretsmanager_secret_version.datasync_include_paths.secret_string
  }

  excludes {
    filter_type = "SIMPLE_PATTERN"
    value       = data.aws_secretsmanager_secret_version.datasync_exclude_path.secret_string
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

  schedule {
    schedule_expression = "cron(0 23 ? * * *)"
  }

  tags = local.tags
}
