locals {
  compact_raw_name        = "${local.project}-maintenance-compact-raw-${local.env}"
  compact_structured_name = "${local.project}-maintenance-compact-structured-${local.env}"
  compact_curated_name    = "${local.project}-maintenance-compact-curated-${local.env}"

  retention_raw_name        = "${local.project}-maintenance-retention-raw-${local.env}"
  retention_structured_name = "${local.project}-maintenance-retention-structured-${local.env}"
  retention_curated_name    = "${local.project}-maintenance-retention-curated-${local.env}"


  compact_job_class   = "uk.gov.justice.digital.job.CompactionJob"
  retention_job_class = "uk.gov.justice.digital.job.VacuumJob"
}

# Glue Job, Compact Raw zone
module "glue_compact_raw_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = local.compact_raw_name
  command_type                  = "glueetl"
  description                   = "Runs compaction on tables in the raw layer"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.compact_raw_name}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.compact_raw_name}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.compact_raw_name}/"
  # Placeholder Script Location
  script_location               = local.glue_placeholder_script_location
  enable_continuous_log_filter  = false
  project_id                    = local.project
  aws_kms_key                   = local.s3_kms_arn
  execution_class               = "FLEX"
  worker_type                   = local.compact_raw_job_worker_type
  number_of_workers             = local.compact_raw_job_num_workers
  max_concurrent                = 1
  region                        = local.account_region
  account                       = local.account_id

  tags = merge(
    local.all_tags,
    {
      Name          = local.compact_raw_name
      Resource_Type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                = local.glue_jobs_latest_jar_location
    "--class"                     = local.compact_job_class
    "--dpr.maintenance.root.path" = "s3://${module.s3_raw_bucket.bucket_id}"
    "--datalake-formats"          = "delta"
    "--dpr.log.level"             = local.compact_raw_job_log_level
  }
}
# Glue Job, Compact Structured zone
module "glue_compact_structured_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = local.compact_structured_name
  command_type                  = "glueetl"
  description                   = "Runs compaction on tables in the structured layer"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.compact_structured_name}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.compact_structured_name}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.compact_structured_name}/"
  # Placeholder Script Location
  script_location               = local.glue_placeholder_script_location
  enable_continuous_log_filter  = false
  project_id                    = local.project
  aws_kms_key                   = local.s3_kms_arn
  execution_class               = "FLEX"
  worker_type                   = local.compact_structured_job_worker_type
  number_of_workers             = local.compact_structured_job_num_workers
  max_concurrent                = 1
  region                        = local.account_region
  account                       = local.account_id

  tags = merge(
    local.all_tags,
    {
      Name          = local.compact_structured_name
      Resource_Type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                = local.glue_jobs_latest_jar_location
    "--class"                     = local.compact_job_class
    "--dpr.maintenance.root.path" = "s3://${module.s3_structured_bucket.bucket_id}"
    "--datalake-formats"          = "delta"
    "--dpr.log.level"             = local.compact_structured_job_log_level
  }
}
# Glue Job, Compact Curated zone
module "glue_compact_curated_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = local.compact_curated_name
  command_type                  = "glueetl"
  description                   = "Runs compaction on tables in the curated layer"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.compact_curated_name}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.compact_curated_name}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.compact_curated_name}/"
  # Placeholder Script Location
  script_location               = local.glue_placeholder_script_location
  enable_continuous_log_filter  = false
  project_id                    = local.project
  aws_kms_key                   = local.s3_kms_arn
  execution_class               = "FLEX"
  worker_type                   = local.compact_curated_job_worker_type
  number_of_workers             = local.compact_curated_job_num_workers
  max_concurrent                = 1
  region                        = local.account_region
  account                       = local.account_id

  tags = merge(
    local.all_tags,
    {
      Name          = local.compact_curated_name
      Resource_Type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                = local.glue_jobs_latest_jar_location
    "--class"                     = local.compact_job_class
    "--dpr.maintenance.root.path" = "s3://${module.s3_curated_bucket.bucket_id}"
    "--datalake-formats"          = "delta"
    "--dpr.log.level"             = local.compact_curated_job_log_level
  }
}
# Glue Job, Retention (vacuum) Raw zone
module "glue_retention_raw_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = local.retention_raw_name
  command_type                  = "glueetl"
  description                   = "Runs the vacuum retention job on tables in the raw layer"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.retention_raw_name}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.retention_raw_name}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.retention_raw_name}/"
  # Placeholder Script Location
  script_location               = local.glue_placeholder_script_location
  enable_continuous_log_filter  = false
  project_id                    = local.project
  aws_kms_key                   = local.s3_kms_arn
  execution_class               = "FLEX"
  worker_type                   = local.retention_raw_job_worker_type
  number_of_workers             = local.retention_raw_job_num_workers
  max_concurrent                = 1
  region                        = local.account_region
  account                       = local.account_id

  tags = merge(
    local.all_tags,
    {
      Name          = local.retention_raw_name
      Resource_Type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                = local.glue_jobs_latest_jar_location
    "--class"                     = local.retention_curated_name
    "--dpr.maintenance.root.path" = "s3://${module.s3_raw_bucket.bucket_id}"
    "--datalake-formats"          = "delta"
    "--dpr.log.level"             = local.retention_raw_job_log_level
  }
}
# Glue Job, Retention (vacuum) Structured zone
module "glue_retention_structured_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = local.retention_structured_name
  command_type                  = "glueetl"
  description                   = "Runs the vacuum retention job on tables in the structured layer"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.retention_structured_name}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.retention_structured_name}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.retention_structured_name}/"
  # Placeholder Script Location
  script_location               = local.glue_placeholder_script_location
  enable_continuous_log_filter  = false
  project_id                    = local.project
  aws_kms_key                   = local.s3_kms_arn
  execution_class               = "FLEX"
  worker_type                   = local.retention_structured_job_worker_type
  number_of_workers             = local.retention_structured_job_num_workers
  max_concurrent                = 1
  region                        = local.account_region
  account                       = local.account_id

  tags = merge(
    local.all_tags,
    {
      Name          = local.retention_structured_name
      Resource_Type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                = local.glue_jobs_latest_jar_location
    "--class"                     = local.retention_curated_name
    "--dpr.maintenance.root.path" = "s3://${module.s3_structured_bucket.bucket_id}"
    "--datalake-formats"          = "delta"
    "--dpr.log.level"             = local.retention_structured_job_log_level
  }
}
# Glue Job, Retention (vacuum) Curated zone
module "glue_retention_curated_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = local.retention_curated_name
  command_type                  = "glueetl"
  description                   = "Runs the vacuum retention job on tables in the curated layer"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.retention_curated_name}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.retention_curated_name}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.retention_curated_name}/"
  # Placeholder Script Location
  script_location               = local.glue_placeholder_script_location
  enable_continuous_log_filter  = false
  project_id                    = local.project
  aws_kms_key                   = local.s3_kms_arn
  execution_class               = "FLEX"
  worker_type                   = local.retention_curated_job_worker_type
  number_of_workers             = local.retention_curated_job_num_workers
  max_concurrent                = 1
  region                        = local.account_region
  account                       = local.account_id

  tags = merge(
    local.all_tags,
    {
      Name          = local.retention_curated_name
      Resource_Type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                = local.glue_jobs_latest_jar_location
    "--class"                     = local.retention_curated_name
    "--dpr.maintenance.root.path" = "s3://${module.s3_curated_bucket.bucket_id}"
    "--datalake-formats"          = "delta"
    "--dpr.log.level"             = local.retention_curated_job_log_level
  }
}