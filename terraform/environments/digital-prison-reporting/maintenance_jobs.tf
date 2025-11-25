locals {
  compaction_job_short_name = "${local.project}-maintenance-compaction"
  compaction_job_name       = "${local.compaction_job_short_name}-${local.env}"

  retention_job_short_name = "${local.project}-maintenance-retention"
  retention_job_name       = "${local.retention_job_short_name}-${local.env}"

  curated_zone_nomis_path = "s3://${module.s3_curated_bucket.bucket_id}/nomis/"

  compact_job_class   = "uk.gov.justice.digital.job.CompactionJob"
  retention_job_class = "uk.gov.justice.digital.job.VacuumJob"
}

# Glue Job, Compaction Job
module "glue_compact_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = local.compaction_job_name
  short_name                    = local.compaction_job_short_name
  command_type                  = "glueetl"
  glue_version                  = local.glue_job_version
  description                   = "Runs compaction on tables in the specified zone path.\nArguments:\n--dpr.maintenance.root.path: (Required) Root path on which to run the job.\n--dpr.domain.name: (Optional) The domain tables to include in the compaction. Will run for all tables if not specified.\n--dpr.config.s3.bucket: (Optional) The bucket in which the domain tables configs are located"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.compaction_job_name}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.compaction_job_name}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.compaction_job_name}/"
  # Placeholder Script Location
  script_location             = local.glue_placeholder_script_location
  project_id                  = local.project
  aws_kms_key                 = local.s3_kms_arn
  execution_class             = "FLEX"
  worker_type                 = local.compact_job_worker_type
  number_of_workers           = local.compact_job_num_workers
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = local.glue_log_retention_in_days

  tags = merge(
    local.all_tags,
    {
      dpr-name          = local.compaction_job_name
      dpr-resource-type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                          = local.glue_jobs_latest_jar_location
    "--extra-files"                         = local.shared_log4j_properties_path
    "--class"                               = local.compact_job_class
    "--dpr.config.s3.bucket"                = module.s3_glue_job_bucket.bucket_id
    "--dpr.maintenance.root.path"           = local.curated_zone_nomis_path
    "--datalake-formats"                    = "delta"
    "--dpr.log.level"                       = local.compact_job_log_level
    "--dpr.datastorage.retry.maxAttempts"   = local.maintenance_job_retry_max_attempts
    "--dpr.datastorage.retry.minWaitMillis" = local.maintenance_job_retry_min_wait_millis
    "--dpr.datastorage.retry.maxWaitMillis" = local.maintenance_job_retry_max_wait_millis
  }
}

# Glue Job, Retention (vacuum) Job
module "glue_retention_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = local.retention_job_name
  short_name                    = local.retention_job_short_name
  command_type                  = "glueetl"
  glue_version                  = local.glue_job_version
  description                   = "Runs the vacuum retention job on tables in the specified zone path.\nArguments:\n--dpr.maintenance.root.path: (Required) Root path on which to run the job.\n--dpr.domain.name: (Optional) The domain tables to include in the compaction. Will run for all tables if not specified.\n--dpr.config.s3.bucket: (Optional) The bucket in which the domain tables configs are located"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.retention_job_name}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.retention_job_name}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.retention_job_name}/"
  # Placeholder Script Location
  script_location             = local.glue_placeholder_script_location
  project_id                  = local.project
  aws_kms_key                 = local.s3_kms_arn
  execution_class             = "FLEX"
  worker_type                 = local.retention_job_worker_type
  number_of_workers           = local.retention_job_num_workers
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = local.glue_log_retention_in_days

  tags = merge(
    local.all_tags,
    {
      dpr-name          = local.retention_job_name
      dpr-resource-type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                          = local.glue_jobs_latest_jar_location
    "--extra-files"                         = local.shared_log4j_properties_path
    "--class"                               = local.retention_job_class
    "--dpr.config.s3.bucket"                = module.s3_glue_job_bucket.bucket_id
    "--dpr.maintenance.root.path"           = local.curated_zone_nomis_path
    "--datalake-formats"                    = "delta"
    "--dpr.log.level"                       = local.retention_job_log_level
    "--dpr.datastorage.retry.maxAttempts"   = local.maintenance_job_retry_max_attempts
    "--dpr.datastorage.retry.minWaitMillis" = local.maintenance_job_retry_min_wait_millis
    "--dpr.datastorage.retry.maxWaitMillis" = local.maintenance_job_retry_max_wait_millis
  }
}
