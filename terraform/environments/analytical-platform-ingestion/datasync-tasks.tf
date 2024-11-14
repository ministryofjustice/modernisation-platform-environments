resource "aws_datasync_task" "dom1_hq_pgo_shared_group_sis_case_management_investigations" {
  name                     = "dom1-hq-pgo-shared-group-sis-case-management-investigations"
  source_location_arn      = aws_datasync_location_smb.dom1_hq_pgo_shared_group_sis_case_management_investigations.arn
  destination_location_arn = aws_datasync_location_s3.dom1_hq_pgo_shared_group_sis_case_management_investigations.arn
  cloudwatch_log_group_arn = module.datasync_task_logs.cloudwatch_log_group_arn

  task_report_config {
    report_level         = "SUCCESSES_AND_ERRORS"
    output_type          = "STANDARD"
    s3_object_versioning = "INCLUDE"

    s3_destination {
      bucket_access_role_arn = module.datasync_iam_role.iam_role_arn
      s3_bucket_arn          = module.datasync_bucket.s3_bucket_arn
      subdirectory           = "datasync/reports/dom1/hq/pgo/shared/group/sis-case-management/investigations/"
    }
  }

  tags = local.tags
}
