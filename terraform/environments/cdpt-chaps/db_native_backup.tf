resource "aws_db_option_group" "sqlserver_native_backup" {
  name                     = local.native_backup_option_group
  option_group_description = "CHAPS ${local.environment} SQL Server native backup to S3"
  engine_name              = "sqlserver-web"
  major_engine_version     = "14.00"

  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"

    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.rds_native_backup.arn
    }
  }

  tags = local.tags
}
