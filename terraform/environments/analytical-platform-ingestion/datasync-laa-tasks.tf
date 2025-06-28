locals {
  # Only create these resources if we're in the production environment
  laa_buckets = local.environment == "production" ? jsondecode(data.aws_secretsmanager_secret_version.laa_data_analysis_bucket_list[0].secret_string).buckets : []
}

resource "aws_datasync_location_s3" "laa_bucket_locations" {
  for_each = toset(nonsensitive(local.laa_buckets))

  s3_bucket_arn = module.laa_data_analysis_bucket[0].s3_bucket_arn
  subdirectory  = "/${each.key}"

  s3_config {
    bucket_access_role_arn = module.datasync_laa_data_analysis_iam_role[0].iam_role_arn
  }
}

resource "aws_datasync_location_s3" "source_bucket_locations" {
  for_each = toset(nonsensitive(local.laa_buckets))

  s3_bucket_arn = "arn:aws:s3:::${each.key}"
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = module.datasync_laa_data_analysis_iam_role[0].iam_role_arn
  }
}

# resource "aws_datasync_task" "laa_data_analysis_tasks" {
#   for_each = toset(nonsensitive(local.laa_buckets))

#   name                     = "laa-data-analysis-${each.key}-to-dedicated"
#   source_location_arn      = aws_datasync_location_s3.source_bucket_locations[each.key].arn
#   destination_location_arn = aws_datasync_location_s3.laa_bucket_locations[each.key].arn
#   cloudwatch_log_group_arn = module.datasync_task_logs.cloudwatch_log_group_arn

#   # Configure the task to preserve the directory structure
#   options {
#     preserve_deleted_files         = "PRESERVE"
#     preserve_devices               = "NONE"
#     verify_mode                    = "ONLY_FILES_TRANSFERRED"
#     posix_permissions              = "PRESERVE"
#     uid                            = "NONE"
#     gid                            = "NONE"
#     atime                          = "BEST_EFFORT"
#     mtime                          = "PRESERVE"
#     bytes_per_second               = -1
#     task_queueing                  = "ENABLED"
#     transfer_mode                  = "CHANGED"
#     security_descriptor_copy_flags = "NONE"
#     object_tags                    = "PRESERVE"
#     overwrite_mode                 = "NEVER"
#     log_level                      = "TRANSFER"
#   }

#   depends_on = [
#     aws_datasync_location_s3.laa_bucket_locations,
#     aws_datasync_location_s3.source_bucket_locations
#   ]
# }

