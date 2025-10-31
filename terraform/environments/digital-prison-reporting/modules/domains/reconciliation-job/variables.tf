variable "project_id" {
  type        = string
  description = "(Required) Project Short ID that will be used for resources."
}

variable "env" {
  type        = string
  description = "(Required) The environment we are deploying into"
}

variable "account_id" {
  description = "AWS Account ID."
  type        = string
}

variable "script_file_version" {
  type        = string
  description = "The filename of the glue script, including version"
}

variable "create_job" {
  description = "Enable Reconciliation Job, True or False"
  type        = bool
  default     = false
}

variable "batch_only" {
  description = "Determines if the pipeline is batch only, True or False?"
  type        = bool
  default     = false
}

variable "create_role" {
  description = "(Optional) Create AWS IAM role associated with the job."
  type        = bool
  default     = false
}

variable "job_name" {
  description = "Name of the Glue Reconciliation Job"
  type        = string
}

variable "short_name" {
  description = "Short name for the Glue Reconciliation Job"
  type        = string
}

variable "create_sec_conf" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS Glue Security Configuration associated with the job."
}

variable "temp_dir" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a temporary directory for the job."
}

variable "spark_event_logs" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a Spark Event Logs directory for the job."
}

variable "enable_continuous_log_filter" {
  type        = bool
  default     = false
  description = "(Optional) Specifies a standard filter or no filter when you create or edit a job enabled for continuous logging."
}

variable "execution_class" {
  default     = "STANDARD"
  description = "Execution CLass STANDARD or FLEX"
  type        = string
}

variable "worker_type" {
  type        = string
  default     = "G.1X"
  description = "(Optional) The type of predefined worker that is allocated when a job runs."

  validation {
    condition     = contains(["Standard", "G.025X", "G.1X", "G.2X"], var.worker_type)
    error_message = "Accepts a value of Standard, G.025X, G.1X, or G.2X."
  }
}

variable "s3_kms_arn" {
  type        = string
  default     = ""
  description = "(Optional) The ARN of the kMS Key associated to S3"
}

variable "account_region" {
  description = "Current AWS Region."
  default     = "eu-west-2"
  type        = string
}

variable "num_workers" {
  type        = number
  default     = 2
  description = "(Optional) The number of workers of a defined workerType that are allocated when a job runs."
}

variable "max_concurrent_runs" {
  type        = number
  default     = 1
  description = "(Optional) The maximum number of concurrent runs allowed for a job."
}

variable "log_group_retention_in_days" {
  type        = number
  default     = 7
  description = "(Optional) The default number of days log events retained in the glue job log group."
}

variable "connections" {
  type        = list(string)
  default     = []
  description = "The list of Glue connections used for the batch job."
}

variable "additional_secret_arns" {
  type        = list(string)
  default     = []
  description = "(Optional) The list of additional secrets this job needs access to."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}

variable "glue_job_arguments" {
  type        = map(string)
  default     = {}
  description = "(Optional) Arguments for the Reconciliation job"
}

variable "job_schedule" {
  description = "Cron schedule for the reconciliation job. Leave unset for no schedule."
  default     = ""
  type        = string

  validation {
    condition     = var.batch_only && (var.job_schedule != "") ? false : true
    error_message = "Reconciliation job can only be scheduled when batch_only = false"
  }
}

variable "enable_spark_ui" {
  type        = string
  default     = "true"
  description = "UI Enabled by default, override with False"
}