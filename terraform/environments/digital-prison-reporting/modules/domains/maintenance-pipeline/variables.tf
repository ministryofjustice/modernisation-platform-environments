variable "setup_maintenance_pipeline" {
  description = "Enable Maintenance Pipeline, True or False ?"
  type        = bool
  default     = false

  validation {
    condition     = var.setup_maintenance_pipeline ? !var.batch_only : true
    error_message = "Maintenance pipeline can only be created when batch_only = false"
  }
}

variable "batch_only" {
  description = "Determines if the pipeline is batch only, True or False?"
  type        = bool
  default     = false
}

variable "maintenance_pipeline_name" {
  description = "Name for Maintenance Pipeline"
  type        = string
}

variable "step_function_execution_role_arn" {
  type        = string
  description = "The ARN of the step function execution role"
}

variable "glue_maintenance_retention_job" {
  description = "Name of glue job which vacuums the delta tables"
  type        = string
}

variable "glue_maintenance_compaction_job" {
  description = "Name of glue job which compacts the delta tables"
  type        = string
}

variable "dms_replication_task_arn" {
  description = "ARN of the replication task"
  type        = string
}

variable "replication_task_id" {
  description = "ID of the replication task"
  type        = string
}

variable "glue_reporting_hub_cdc_jobname" {
  description = "Glue Reporting Hub CDC JobName"
  type        = string
}

variable "s3_glue_bucket_id" {
  description = "S3, Glue Bucket ID"
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

variable "glue_unprocessed_raw_files_check_job" {
  description = "Name of job to ensure raw files have been processed"
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

variable "glue_archive_job" {
  description = "Name of the glue job which archives the raw data"
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

variable "processed_files_check_wait_interval_seconds" {
  description = "Amount of seconds between checks to s3 if all files have been processed"
  type        = number
}

variable "processed_files_check_max_attempts" {
  description = "Maximum number of attempts to check if all files have been processed"
  type        = number
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
  description = "(Optional) Key-value map of resource tags."
  type        = map(string)
  default     = {}
}

variable "domain" {
  description = "Domain Name"
  type        = string
}