module "glue_reporting_hub_cdc_job" {
  source                        = "../modules/glue_job"
  create_job                    = local.setup_cdc_job
  name                          = var.glue_job_name
  short_name                    = var.glue_job_short_name
  command_type                  = "gluestreaming"
  description                   = var.description
  create_security_configuration = var.create_sec_conf
  job_language                  = var.language
  checkpoint_dir                = var.checkpoint_dir
  temp_dir                      = var.temp_dir
  spark_event_logs              = var.spark_event_logs
  script_location               = var.script_location
  enable_continuous_log_filter  = var.enable_cont_log_filter
  project_id                    = var.project_id
  aws_kms_key                   = var.s3_kms_arn
  execution_class               = var.execution_class
  additional_policies           = var.additional_policies
  worker_type                   = var.reporting_hub_cdc_job_worker_type
  number_of_workers             = var.reporting_hub_cdc_job_num_workers
  max_concurrent                = var.max_concurrent
  region                        = var.account_region
  account                       = var.account_id
  log_group_retention_in_days   = var.log_group_retention_in_days

  arguments = var.arguments

  tags = merge(
    var.tags,
    local.all_tags,
    {
      Resource_Type = "Glue Job"
    }
  )  
}