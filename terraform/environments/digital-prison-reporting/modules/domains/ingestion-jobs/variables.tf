## Glue job BATCH
variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}

variable "glue_batch_arguments" {
  type    = map(any)
  default = {}
}

variable "setup_batch_job" {
  description = "Enable Batch Job, True or False"
  type        = bool
  default     = false  
}

variable "glue_batch_job_name" {
  description = "Name of the Glue CDC Job"
  default     = ""  
}

variable "glue_batch_job_short_name" {
  description = "Name of the Glue CDC Job"
  default     = ""  
}

variable "glue_batch_description" {
  description = "Job Description"
  default     = ""  
}

variable "glue_batch_create_sec_conf" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS Glue Security Configuration associated with the job."
}

variable "glue_batch_log_group_retention_in_days" {
  type        = number
  default     = 1
  description = "(Optional) The default number of days log events retained in the glue job log group."
}


variable "glue_batch_language" {
  type        = string
  default     = "python"
  description = "(Optional) The script programming language."

  validation {
    condition     = contains(["scala", "python"], var.glue_batch_language)
    error_message = "Accepts a value of 'scala' or 'python'."
  }
}

variable "glue_batch_temp_dir" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a temporary directory for the job."
}

variable "glue_batch_checkpoint_dir" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a Checkoint directory for the job."
}

variable "glue_batch_spark_event_logs" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a Spark Event Logs directory for the job."
}

variable "glue_batch_script_location" {
  type        = string
  description = "(Optional) Specifies the S3 path to a script that executes a job."
  default     = ""
}

variable "glue_batch_enable_cont_log_filter" {
  type        = bool
  default     = true
  description = "(Optional) Specifies a standard filter or no filter when you create or edit a job enabled for continuous logging."
}

variable "glue_batch_execution_class" {
  default     = "STANDARD"
  description = "Execution CLass Standard or FLex"
}

variable "glue_batch_job_worker_type" {
  type        = string
  default     = "G.1X"
  description = "(Optional) The type of predefined worker that is allocated when a job runs."

  validation {
    condition     = contains(["Standard", "G.1X", "G.2X"], var.glue_batch_job_worker_type)
    error_message = "Accepts a value of Standard, G.1X, or G.2X."
  }
}

variable "glue_batch_job_num_workers" {
  type        = number
  default     = 2
  description = "(Optional) The number of workers of a defined workerType that are allocated when a job runs."
}

variable "glue_batch_additional_policies" {
  type        = string
  default     = ""
  description = "(Optional) The list of Policies used for this job."
}

variable "glue_batch_max_concurrent" {
  type        = number
  default     = 1
  description = "(Optional) The maximum number of concurrent runs allowed for a job."
}

variable "glue_batch_create_role" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS IAM role associated with the job."
}

variable "glue_cdc_script_version" {
}

variable "setup_cdc_job" {}
variable "glue_cdc_create_role" {}
variable "glue_cdc_create_sec_conf" {}
variable "glue_cdc_job_worker_type" {}
variable "glue_cdc_job_num_workers" {}