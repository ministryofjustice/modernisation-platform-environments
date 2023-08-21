# Glue Job, Compact Raw zone
module "glue_compact_raw_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-maintenance-compact-raw-${local.env}"
  command_type                  = "glueetl"
  description                   = "Runs compaction on tables in the raw layer"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-maintenance-compact-raw-${local.env}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.project}-maintenance-compact-raw-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-maintenance-compact-raw-${local.env}/"
  # Placeholder Script Location
  script_location              = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/scripts/digital-prison-reporting-jobs-vLatest.scala"
  enable_continuous_log_filter = false
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn
  execution_class   = "FLEX"
  worker_type       = local.compact_raw_job_worker_type
  number_of_workers = local.compact_raw_job_num_workers
  max_concurrent    = 1
  region            = local.account_region
  account           = local.account_id

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-maintenance-compact-raw-${local.env}"
      Resource_Type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                   = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/jars/digital-prison-reporting-jobs-vLatest-all.jar"
    "--class"                        = "uk.gov.justice.digital.job.CompactionJob"
    "--dpr.maintenance.root.path"    = "s3://${module.s3_raw_bucket.bucket_id}"
    "--datalake-formats"             = "delta"
    "--dpr.log.level"                = local.compact_raw_job_log_level
  }
}
# Glue Job, Compact Structured zone
module "glue_compact_structured_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-maintenance-compact-structured-${local.env}"
  command_type                  = "glueetl"
  description                   = "Runs compaction on tables in the structured layer"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-maintenance-compact-structured-${local.env}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.project}-maintenance-compact-structured-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-maintenance-compact-structured-${local.env}/"
  # Placeholder Script Location
  script_location              = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/scripts/digital-prison-reporting-jobs-vLatest.scala"
  enable_continuous_log_filter = false
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn
  execution_class   = "FLEX"
  worker_type       = local.compact_structured_job_worker_type
  number_of_workers = local.compact_structured_job_num_workers
  max_concurrent    = 1
  region            = local.account_region
  account           = local.account_id

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-maintenance-compact-structured-${local.env}"
      Resource_Type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                   = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/jars/digital-prison-reporting-jobs-vLatest-all.jar"
    "--class"                        = "uk.gov.justice.digital.job.CompactionJob"
    "--dpr.maintenance.root.path"    = "s3://${module.s3_structured_bucket.bucket_id}"
    "--datalake-formats"             = "delta"
    "--dpr.log.level"                = local.compact_structured_job_log_level
  }
}
# Glue Job, Compact Curated zone
module "glue_compact_curated_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-maintenance-compact-curated-${local.env}"
  command_type                  = "glueetl"
  description                   = "Runs compaction on tables in the curated layer"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-maintenance-compact-curated-${local.env}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.project}-maintenance-compact-curated-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-maintenance-compact-curated-${local.env}/"
  # Placeholder Script Location
  script_location              = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/scripts/digital-prison-reporting-jobs-vLatest.scala"
  enable_continuous_log_filter = false
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn
  execution_class   = "FLEX"
  worker_type       = local.compact_curated_job_worker_type
  number_of_workers = local.compact_curated_job_num_workers
  max_concurrent    = 1
  region            = local.account_region
  account           = local.account_id

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-maintenance-compact-curated-${local.env}"
      Resource_Type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                   = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/jars/digital-prison-reporting-jobs-vLatest-all.jar"
    "--class"                        = "uk.gov.justice.digital.job.CompactionJob"
    "--dpr.maintenance.root.path"    = "s3://${module.s3_curated_bucket.bucket_id}"
    "--datalake-formats"             = "delta"
    "--dpr.log.level"                = local.compact_curated_job_log_level
  }
}
# Glue Job, Vacuum Raw zone
module "glue_vacuum_raw_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-maintenance-vacuum-raw-${local.env}"
  command_type                  = "glueetl"
  description                   = "Runs vacuum on tables in the raw layer"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-maintenance-vacuum-raw-${local.env}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.project}-maintenance-vacuum-raw-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-maintenance-vacuum-raw-${local.env}/"
  # Placeholder Script Location
  script_location              = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/scripts/digital-prison-reporting-jobs-vLatest.scala"
  enable_continuous_log_filter = false
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn
  execution_class   = "FLEX"
  worker_type       = local.vacuum_raw_job_worker_type
  number_of_workers = local.vacuum_raw_job_num_workers
  max_concurrent    = 1
  region            = local.account_region
  account           = local.account_id

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-maintenance-vacuum-raw-${local.env}"
      Resource_Type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                   = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/jars/digital-prison-reporting-jobs-vLatest-all.jar"
    "--class"                        = "uk.gov.justice.digital.job.VacuumJob"
    "--dpr.maintenance.root.path"    = "s3://${module.s3_raw_bucket.bucket_id}"
    "--datalake-formats"             = "delta"
    "--dpr.log.level"                = local.vacuum_raw_job_log_level
  }
}
# Glue Job, Vacuum Structured zone
module "glue_vacuum_structured_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-maintenance-vacuum-structured-${local.env}"
  command_type                  = "glueetl"
  description                   = "Runs vacuum on tables in the structured layer"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-maintenance-vacuum-structured-${local.env}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.project}-maintenance-vacuum-structured-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-maintenance-vacuum-structured-${local.env}/"
  # Placeholder Script Location
  script_location              = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/scripts/digital-prison-reporting-jobs-vLatest.scala"
  enable_continuous_log_filter = false
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn
  execution_class   = "FLEX"
  worker_type       = local.vacuum_structured_job_worker_type
  number_of_workers = local.vacuum_structured_job_num_workers
  max_concurrent    = 1
  region            = local.account_region
  account           = local.account_id

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-maintenance-vacuum-structured-${local.env}"
      Resource_Type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                   = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/jars/digital-prison-reporting-jobs-vLatest-all.jar"
    "--class"                        = "uk.gov.justice.digital.job.VacuumJob"
    "--dpr.maintenance.root.path"    = "s3://${module.s3_structured_bucket.bucket_id}"
    "--datalake-formats"             = "delta"
    "--dpr.log.level"                = local.vacuum_structured_job_log_level
  }
}
# Glue Job, Vacuum Curated zone
module "glue_vacuum_curated_job" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = "${local.project}-maintenance-vacuum-curated-${local.env}"
  command_type                  = "glueetl"
  description                   = "Runs vacuum on tables in the curated layer"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.project}-maintenance-vacuum-curated-${local.env}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.project}-maintenance-vacuum-curated-${local.env}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.project}-maintenance-vacuum-curated-${local.env}/"
  # Placeholder Script Location
  script_location              = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/scripts/digital-prison-reporting-jobs-vLatest.scala"
  enable_continuous_log_filter = false
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn
  execution_class   = "FLEX"
  worker_type       = local.vacuum_curated_job_worker_type
  number_of_workers = local.vacuum_curated_job_num_workers
  max_concurrent    = 1
  region            = local.account_region
  account           = local.account_id

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-maintenance-vacuum-curated-${local.env}"
      Resource_Type = "Glue Job"
    }
  )

  arguments = {
    "--extra-jars"                   = "s3://${local.project}-artifact-store-${local.environment}/build-artifacts/digital-prison-reporting-jobs/jars/digital-prison-reporting-jobs-vLatest-all.jar"
    "--class"                        = "uk.gov.justice.digital.job.VacuumJob"
    "--dpr.maintenance.root.path"    = "s3://${module.s3_curated_bucket.bucket_id}"
    "--datalake-formats"             = "delta"
    "--dpr.log.level"                = local.vacuum_curated_job_log_level
  }
}