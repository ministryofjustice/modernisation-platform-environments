# STEP FUNCTION, Pipeline
variable "setup_data_ingestion_pipeline" {
  description = "Enable Data Ingestion Pipeline, True or False ?"
  type        = bool
  default     = false
}

variable "batch_only" {
  description = "Determines if the pipeline is batch only, True or False?"
  type        = bool
  default     = false
}

variable "split_pipeline" {
  description = "Determines if the pipeline is split into a Full-Load and a separate CDC tasks, True or False?"
  type        = bool
  default     = false

  validation {
    condition     = var.batch_only ? var.split_pipeline == false : true
    error_message = "split_pipeline can only be 'true' when batch_only = false"
  }
}

variable "data_ingestion_pipeline" {
  description = "Name for Data Ingestion Pipeline"
  type        = string
}

variable "pipeline_dms_task_time_out" {
  description = "DMS Task Timeout"
  type        = number
  default     = 86400 # 24 hours
}

variable "step_function_execution_role_arn" {
  type        = string
  description = "The ARN of the step function execution role"
}

variable "glue_s3_data_deletion_job" {
  description = "Name of glue job which deletes parquet files from s3 bucket(s)"
  type        = string
}

variable "dms_replication_task_arn" {
  description = "ARN of the replication task"
  type        = string
}

variable "dms_cdc_replication_task_arn" {
  description = "ARN of the CDC replication task"
  type        = string

  validation {
    condition     = var.split_pipeline == true ? var.dms_cdc_replication_task_arn != null : var.dms_cdc_replication_task_arn == null
    error_message = "dms_cdc_replication_task_arn is only allowed when split_pipeline = true"
  }
}

variable "replication_task_id" {
  description = "ID of the replication task"
  type        = string
}

variable "cdc_replication_task_id" {
  description = "ID of the CDC replication task"
  type        = string

  validation {
    condition     = var.split_pipeline == true ? var.cdc_replication_task_id != null : var.cdc_replication_task_id == null
    error_message = "cdc_replication_task_id is only allowed when split_pipeline = true"
  }
}

variable "pipeline_notification_lambda_function" {
  description = "Pipeline Notification Lambda Name"
  type        = string
}

variable "pipeline_notification_lambda_function_ignore_dms_failure" {
  description = "Pipeline notification lambda function ignores DMS task failures"
  type        = bool
  default     = false
}

variable "set_cdc_dms_start_time_job" {
  description = "Name of the Glue job which sets the start time of the CDC DMS task"
  type        = string

  validation {
    condition     = var.split_pipeline == true ? var.set_cdc_dms_start_time_job != null : var.set_cdc_dms_start_time_job == null
    error_message = "set_cdc_dms_start_time_job is only allowed when split_pipeline = true"
  }
}

variable "glue_reporting_hub_batch_jobname" {
  description = "Glue Reporting Hub Batch JobName"
  type        = string
}

variable "glue_reporting_hub_cdc_jobname" {
  description = "Glue Reporting Hub CDC JobName"
  type        = string
}

variable "glue_reconciliation_job" {
  description = "Name of the reconciliation glue job"
  type        = string
}

variable "glue_reconciliation_job_worker_type" {
  description = "(Optional) Worker type to use for the reconciliation job"
  type        = string
  default     = "G.1X"

  validation {
    condition     = contains(["G.1X", "G.2X", "G.4X", "G.8X"], var.glue_reconciliation_job_worker_type)
    error_message = "Worker type can only be one of G.1X, G.2X, G.4X, G.8X"
  }
}

variable "glue_reconciliation_job_num_workers" {
  description = "(Optional) Number of workers to use for the reconciliation job. Must be >= 2"
  type        = number
  default     = 2

  validation {
    condition     = var.glue_reconciliation_job_num_workers >= 2
    error_message = "Number of workers must be >= 2"
  }
}

variable "s3_glue_bucket_id" {
  description = "S3, Glue Bucket ID"
  type        = string
}

variable "s3_raw_bucket_id" {
  description = "S3, RAW Bucket ID"
  type        = string
}

variable "s3_raw_archive_bucket_id" {
  description = "S3, RAW Archive Bucket ID"
  type        = string
}

variable "s3_structured_bucket_id" {
  description = "S3, Structured Bucket ID"
  type        = string
}

variable "s3_curated_bucket_id" {
  description = "S3, Curated Bucket ID"
  type        = string
}

variable "s3_temp_reload_bucket_id" {
  description = "S3 Bucket ID for the temporary location to store reload data"
  type        = string
}

variable "glue_stop_glue_instance_job" {
  description = "Name of job to stop the current running instance of the streaming job"
  type        = string
}

variable "stop_dms_task_job" {
  description = "Name of job to stop a running DMS task"
  type        = string
}

variable "glue_trigger_activation_job" {
  description = "Name of job to which activates/deactivates a glue trigger"
  type        = string
}

variable "archive_job_trigger_name" {
  description = "Name of the trigger for a glue trigger"
  type        = string
}

variable "glue_archive_job" {
  description = "Name of the glue job which archives the raw data"
  type        = string
}

variable "glue_s3_file_transfer_job" {
  description = "Name of s3 file transfer job"
  type        = string
}

variable "glue_hive_table_creation_jobname" {
  description = "Glue Hive Table Creation JobName"
  type        = string
}

variable "glue_switch_prisons_hive_data_location_job" {
  description = "Name of glue job to switch the prisons hive data location"
  type        = string
}

variable "glue_maintenance_retention_job" {
  description = "Name of glue job which vacuums the delta tables"
  type        = string
}

variable "glue_maintenance_compaction_job" {
  description = "Name of glue job which compacts the delta tables"
  type        = string
}

variable "s3_structured_path" {
  description = "S3 Path for Structured Data"
  type        = string
}

variable "s3_curated_path" {
  description = "S3 Path for Curated Data"
  type        = string
}

variable "compaction_structured_worker_type" {
  description = "(Optional) Worker type to use for the compaction job in structured zone"
  type        = string
  default     = "G.1X"

  validation {
    condition     = contains(["G.1X", "G.2X", "G.4X", "G.8X"], var.compaction_structured_worker_type)
    error_message = "Worker type can only be one of G.1X, G.2X, G.4X, G.8X"
  }
}

variable "compaction_structured_num_workers" {
  description = "(Optional) Number of workers to use for the compaction job in structured zone. Must be >= 2"
  type        = number
  default     = 2

  validation {
    condition     = var.compaction_structured_num_workers >= 2
    error_message = "Number of workers must be >= 2"
  }
}

variable "compaction_curated_worker_type" {
  description = "(Optional) Worker type to use for the compaction job in curated zone"
  type        = string
  default     = "G.1X"

  validation {
    condition     = contains(["G.1X", "G.2X", "G.4X", "G.8X"], var.compaction_curated_worker_type)
    error_message = "Worker type can only be one of G.1X, G.2X, G.4X, G.8X"
  }
}

variable "compaction_curated_num_workers" {
  description = "(Optional) Number of workers to use for the compaction job in curated zone. Must be >= 2"
  type        = number
  default     = 2

  validation {
    condition     = var.compaction_curated_num_workers >= 2
    error_message = "Number of workers must be >= 2"
  }
}

variable "retention_structured_worker_type" {
  description = "(Optional) Worker type to use for the retention job in structured zone"
  type        = string
  default     = "G.1X"

  validation {
    condition     = contains(["G.1X", "G.2X", "G.4X", "G.8X"], var.retention_structured_worker_type)
    error_message = "Worker type can only be one of G.1X, G.2X, G.4X, G.8X"
  }
}

variable "retention_structured_num_workers" {
  description = "(Optional) Number of workers to use for the retention job in structured zone. Must be >= 2"
  type        = number
  default     = 2

  validation {
    condition     = var.retention_structured_num_workers >= 2
    error_message = "Number of workers must be >= 2"
  }
}

variable "retention_curated_worker_type" {
  description = "(Optional) Worker type to use for the retention job in curated zone"
  type        = string
  default     = "G.1X"

  validation {
    condition     = contains(["G.1X", "G.2X", "G.4X", "G.8X"], var.retention_curated_worker_type)
    error_message = "Worker type can only be one of G.1X, G.2X, G.4X, G.8X"
  }
}

variable "retention_curated_num_workers" {
  description = "(Optional) Number of workers to use for the retention job in curated zone. Must be >= 2"
  type        = number
  default     = 2

  validation {
    condition     = var.retention_curated_num_workers >= 2
    error_message = "Number of workers must be >= 2"
  }
}

variable "glue_s3_max_attempts" {
  description = "The maximum number of attempts when making requests to S3"
  type        = number
}

variable "glue_s3_retry_min_wait_millis" {
  description = "The minimum wait duration in millis before a request to S3 is retried"
  type        = number
}

variable "glue_s3_retry_max_wait_millis" {
  description = "The maximum wait duration in millis before a request to S3 is retried"
  type        = number
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}

variable "domain" {
  type        = string
  description = "Domain Name"
}