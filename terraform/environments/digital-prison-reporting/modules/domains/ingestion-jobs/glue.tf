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
  region                        = var.account_region
  account                       = var.account_id
  log_group_retention_in_days   = var.glue_log_group_retention_in_days
  connections                   = var.glue_cdc_job_connections

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

  arguments = var.glue_batch_arguments

  tags = merge(
    var.tags,
    {
      Resource_Type = "Glue Job"
    }
  )
}

