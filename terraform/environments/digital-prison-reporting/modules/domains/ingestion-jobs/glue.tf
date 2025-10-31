# CDC JOB
module "glue_reporting_hub_cdc_job" {
  source                        = "../../glue_job"
  create_job                    = var.setup_cdc_job
  create_role                   = var.glue_cdc_create_role # Needs to Set to TRUE
  name                          = var.glue_cdc_job_name
  short_name                    = var.glue_cdc_job_short_name
  command_type                  = "gluestreaming"
  description                   = var.glue_cdc_description
  create_security_configuration = var.glue_cdc_create_sec_conf
  job_language                  = var.glue_cdc_language
  checkpoint_dir                = var.glue_cdc_checkpoint_dir
  temp_dir                      = var.glue_cdc_temp_dir
  spark_event_logs              = var.glue_cdc_spark_event_logs
  script_location               = "s3://${var.project_id}-artifact-store-${var.env}/build-artifacts/digital-prison-reporting-jobs/scripts/${var.script_version}"
  enable_continuous_log_filter  = var.glue_cdc_enable_cont_log_filter
  project_id                    = var.project_id
  aws_kms_key                   = var.s3_kms_arn
  execution_class               = var.glue_cdc_execution_class
  additional_policies           = var.glue_cdc_additional_policies
  worker_type                   = var.glue_cdc_job_worker_type
  number_of_workers             = var.glue_cdc_job_num_workers
  max_concurrent                = var.glue_cdc_max_concurrent
  maintenance_window            = var.glue_cdc_maintenance_window
  region                        = var.account_region
  account                       = var.account_id
  log_group_retention_in_days   = var.glue_log_group_retention_in_days
  connections                   = var.glue_cdc_job_connections
  additional_secret_arns        = var.glue_cdc_job_additional_secret_arns
  enable_spark_ui               = var.enable_spark_ui

  arguments = var.glue_cdc_arguments

  tags = merge(
    var.tags,
    {
      Resource_Type = "Glue Job"
    }
  )
}

# Batch JOB
# Glue Job, Reporting Hub Batch
module "glue_reporting_hub_batch_job" {
  source                        = "../../glue_job"
  create_job                    = var.setup_batch_job
  create_role                   = var.glue_batch_create_role # Needs to Set to TRUE
  name                          = var.glue_batch_job_name
  short_name                    = var.glue_batch_job_short_name
  command_type                  = "glueetl"
  description                   = var.glue_batch_description
  create_security_configuration = var.glue_batch_create_sec_conf
  job_language                  = var.glue_batch_language
  temp_dir                      = var.glue_batch_temp_dir
  spark_event_logs              = var.glue_batch_spark_event_logs
  script_location               = "s3://${var.project_id}-artifact-store-${var.env}/build-artifacts/digital-prison-reporting-jobs/scripts/${var.script_version}"
  enable_continuous_log_filter  = var.glue_batch_enable_cont_log_filter
  project_id                    = var.project_id
  aws_kms_key                   = var.s3_kms_arn
  execution_class               = var.glue_batch_execution_class
  additional_policies           = var.glue_batch_additional_policies
  worker_type                   = var.glue_batch_job_worker_type
  number_of_workers             = var.glue_batch_job_num_workers
  max_concurrent                = var.glue_batch_max_concurrent #64
  region                        = var.account_region
  account                       = var.account_id
  log_group_retention_in_days   = var.glue_log_group_retention_in_days
  connections                   = var.glue_batch_job_connections
  additional_secret_arns        = var.glue_batch_job_additional_secret_arns
  enable_spark_ui               = var.enable_spark_ui

  arguments = var.glue_batch_arguments

  tags = merge(
    var.tags,
    {
      Resource_Type = "Glue Job"
    }
  )
}

# Glue Job, Check All Raw Files Have Been Processed Job
module "unprocessed_raw_files_check_job" {
  source                        = "../../glue_job"
  create_job                    = var.batch_only ? false : var.setup_unprocessed_raw_files_check_job
  create_role                   = var.batch_only ? false : var.glue_unprocessed_raw_files_check_create_role # Needs to Set to TRUE
  name                          = var.glue_unprocessed_raw_files_check_job_name
  short_name                    = var.glue_unprocessed_raw_files_check_job_short_name
  command_type                  = "glueetl"
  description                   = var.glue_unprocessed_raw_files_check_description
  create_security_configuration = var.glue_unprocessed_raw_files_check_create_sec_conf
  job_language                  = var.glue_unprocessed_raw_files_check_language
  temp_dir                      = var.glue_unprocessed_raw_files_check_temp_dir
  spark_event_logs              = var.glue_unprocessed_raw_files_check_spark_event_logs
  script_location               = "s3://${var.project_id}-artifact-store-${var.env}/build-artifacts/digital-prison-reporting-jobs/scripts/${var.script_version}"
  enable_continuous_log_filter  = var.glue_unprocessed_raw_files_check_enable_cont_log_filter
  project_id                    = var.project_id
  aws_kms_key                   = var.s3_kms_arn
  execution_class               = var.glue_unprocessed_raw_files_check_execution_class
  additional_policies           = var.glue_unprocessed_raw_files_check_additional_policies
  worker_type                   = var.glue_unprocessed_raw_files_check_job_worker_type
  number_of_workers             = var.glue_unprocessed_raw_files_check_job_num_workers
  max_concurrent                = var.glue_unprocessed_raw_files_check_max_concurrent #64
  region                        = var.account_region
  account                       = var.account_id
  log_group_retention_in_days   = var.glue_log_group_retention_in_days
  enable_spark_ui               = var.enable_spark_ui

  arguments = var.glue_unprocessed_raw_files_check_arguments

  tags = merge(
    var.tags,
    {
      Resource_Type = "Glue Job"
      Jira          = "DPR2-713"
    }
  )
}

# Archive JOB
# Glue Job, Reporting Hub Archive
module "glue_archive_job" {
  source                        = "../../glue_job"
  create_job                    = var.batch_only ? false : var.setup_archive_job
  create_role                   = var.batch_only ? false : var.glue_archive_create_role # Needs to Set to TRUE
  name                          = var.glue_archive_job_name
  short_name                    = var.glue_archive_job_short_name
  command_type                  = "glueetl"
  description                   = var.glue_archive_description
  create_security_configuration = var.glue_archive_create_sec_conf
  job_language                  = var.glue_archive_language
  temp_dir                      = var.glue_archive_temp_dir
  spark_event_logs              = var.glue_archive_spark_event_logs
  script_location               = "s3://${var.project_id}-artifact-store-${var.env}/build-artifacts/digital-prison-reporting-jobs/scripts/${var.script_version}"
  enable_continuous_log_filter  = var.glue_archive_enable_cont_log_filter
  project_id                    = var.project_id
  aws_kms_key                   = var.s3_kms_arn
  execution_class               = var.glue_archive_execution_class
  additional_policies           = var.glue_archive_additional_policies
  worker_type                   = var.glue_archive_job_worker_type
  number_of_workers             = var.glue_archive_job_num_workers
  max_concurrent                = var.glue_archive_max_concurrent #64
  region                        = var.account_region
  account                       = var.account_id
  log_group_retention_in_days   = var.glue_log_group_retention_in_days
  enable_spark_ui               = var.enable_spark_ui

  arguments = var.glue_archive_arguments

  tags = merge(
    var.tags,
    {
      Resource_Type = "Glue Job"
      Jira          = "DPR2-713"
    }
  )
}

# Glue Job, Create Reload Diff Between the Raw Data And Archived Data
module "create_reload_diff_job" {
  source                        = "../../glue_job"
  create_job                    = var.setup_create_reload_diff_job
  create_role                   = var.glue_create_reload_diff_job_role # Needs to Set to TRUE
  name                          = var.glue_create_reload_diff_job_name
  short_name                    = var.glue_create_reload_diff_job_short_name
  command_type                  = "glueetl"
  description                   = var.glue_create_reload_diff_job_description
  create_security_configuration = var.glue_create_reload_diff_job_create_sec_conf
  job_language                  = var.glue_create_reload_diff_job_language
  temp_dir                      = var.glue_create_reload_diff_job_temp_dir
  spark_event_logs              = var.glue_create_reload_diff_job_spark_event_logs
  # Placeholder Script Location
  script_location              = "s3://${var.project_id}-artifact-store-${var.env}/build-artifacts/digital-prison-reporting-jobs/scripts/${var.script_version}"
  enable_continuous_log_filter = var.glue_create_reload_diff_job_enable_cont_log_filter
  project_id                   = var.project_id
  aws_kms_key                  = var.s3_kms_arn
  execution_class              = var.glue_create_reload_diff_job_execution_class
  additional_policies          = var.glue_create_reload_diff_job_additional_policies
  worker_type                  = var.glue_create_reload_diff_job_worker_type
  number_of_workers            = var.glue_create_reload_diff_job_num_workers
  max_concurrent               = var.glue_create_reload_diff_job_max_concurrent #64
  region                       = var.account_region
  account                      = var.account_id
  log_group_retention_in_days  = var.glue_log_group_retention_in_days
  enable_spark_ui              = var.enable_spark_ui

  tags = merge(
    var.tags,
    {
      Resource_Type = "Glue Job"
      Jira          = "DPR2-714"
    }
  )

  arguments = var.glue_create_reload_diff_job_arguments
}

resource "aws_glue_trigger" "glue_file_archive_job_trigger" {
  count    = var.setup_archive_job ? 1 : 0
  name     = "${module.glue_archive_job.name}-trigger"
  schedule = var.glue_archive_job_schedule
  type     = "SCHEDULED"

  actions {
    job_name = module.glue_archive_job.name
  }

  tags = {
    Name          = "${module.glue_archive_job.name}-trigger"
    Resource_Type = "Glue Trigger"
    Jira          = "DPR2-713"
  }
}

