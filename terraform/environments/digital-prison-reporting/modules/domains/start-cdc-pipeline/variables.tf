variable "setup_start_cdc_pipeline" {
  description = "Enable Maintenance Pipeline, True or False"
  type        = bool
  default     = false

  validation {
    condition     = var.setup_start_cdc_pipeline ? !var.batch_only : true
    error_message = "Start CDC pipeline can only be created when batch_only = false"
  }
}

variable "batch_only" {
  description = "Determines if the pipeline is batch only, True or False?"
  type        = bool
  default     = false
}

variable "start_cdc_pipeline" {
  description = "Name for Maintenance Pipeline"
  type        = string
}

variable "step_function_execution_role_arn" {
  type        = string
  description = "The ARN of the step function execution role"
}

variable "replication_task_id" {
  type        = string
  description = "ID of the replication task"
}

variable "dms_replication_task_arn" {
  type        = string
  description = "ARN of the replication task"
}

variable "glue_reporting_hub_cdc_jobname" {
  description = "Glue Reporting Hub CDC JobName"
  type        = string
}

variable "s3_glue_bucket_id" {
  description = "S3, Glue Bucket ID"
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

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags"
}

variable "domain" {
  type        = string
  description = "Domain Name"
}