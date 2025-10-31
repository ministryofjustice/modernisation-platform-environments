locals {
  # Only create these resources if we're in the production environment
  laa_buckets       = local.environment == "production" ? jsondecode(data.aws_secretsmanager_secret_version.laa_data_analysis_bucket_list[0].secret_string).buckets : []
  eu_west_1_buckets = local.environment == "production" ? jsondecode(data.aws_secretsmanager_secret_version.laa_data_analysis_bucket_list[0].secret_string).eu-west-1 : []
  eu_west_2_buckets = local.environment == "production" ? jsondecode(data.aws_secretsmanager_secret_version.laa_data_analysis_bucket_list[0].secret_string).eu-west-2 : []

  source_location_arns = merge(
    { for name, loc in aws_datasync_location_s3.source_bucket_locations_eu_west_1 : name => loc.arn },
    { for name, loc in aws_datasync_location_s3.source_bucket_locations : name => loc.arn }
  )
}

resource "aws_datasync_location_s3" "laa_bucket_locations" {
  for_each = toset(nonsensitive(local.laa_buckets))

  s3_bucket_arn = module.laa_data_analysis_bucket[0].s3_bucket_arn
  subdirectory  = "/${each.key}"

  s3_config {
    bucket_access_role_arn = module.datasync_laa_data_analysis_iam_role[0].iam_role_arn
  }
}

resource "aws_datasync_location_s3" "source_bucket_locations_eu_west_1" {
  provider = aws.eu-west-1
  for_each = toset(nonsensitive(local.eu_west_1_buckets))

  s3_bucket_arn = "arn:aws:s3:::${each.key}"
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = module.datasync_laa_data_analysis_iam_role[0].iam_role_arn
  }
}

resource "aws_datasync_location_s3" "source_bucket_locations" {
  for_each = toset(nonsensitive(local.eu_west_2_buckets))

  s3_bucket_arn = "arn:aws:s3:::${each.key}"
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = module.datasync_laa_data_analysis_iam_role[0].iam_role_arn
  }
}

resource "aws_datasync_task" "laa_data_analysis_tasks" {
  for_each = toset(nonsensitive(local.laa_buckets))

  name                     = "laa-data-analysis-${each.key}-to-dedicated"
  source_location_arn      = local.source_location_arns[each.key]
  destination_location_arn = aws_datasync_location_s3.laa_bucket_locations[each.key].arn
  cloudwatch_log_group_arn = "${module.datasync_enhanced_logs.cloudwatch_log_group_arn}:*"
  task_mode                = "ENHANCED"

  options {
    preserve_deleted_files         = "PRESERVE"
    preserve_devices               = "NONE"
    verify_mode                    = "NONE"
    posix_permissions              = "NONE"
    uid                            = "NONE"
    gid                            = "NONE"
    atime                          = "BEST_EFFORT"
    mtime                          = "PRESERVE"
    bytes_per_second               = -1
    task_queueing                  = "ENABLED"
    transfer_mode                  = "CHANGED"
    security_descriptor_copy_flags = "NONE"
    object_tags                    = "PRESERVE"
    overwrite_mode                 = "NEVER"
    log_level                      = "TRANSFER"
  }

  depends_on = [
    aws_datasync_location_s3.laa_bucket_locations,
    aws_datasync_location_s3.source_bucket_locations_eu_west_1,
    aws_datasync_location_s3.source_bucket_locations,
    module.datasync_enhanced_logs
  ]
}

