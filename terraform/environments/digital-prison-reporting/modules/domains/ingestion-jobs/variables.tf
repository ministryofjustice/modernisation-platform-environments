variable "project_id" {
  type        = string
  description = "(Required) Project Short ID that will be used for resources."
}

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

variable "glue_batch_glue_version" {
  type        = string
  default     = "4.0"
  description = "(Optional) The version of glue to use."
}

variable "setup_batch_job" {
  description = "Enable Batch Job, True or False"
  type        = bool
  default     = false
}

variable "glue_batch_job_name" {
  description = "Name of the Glue CDC Job"
  default     = ""
  type        = string
}

variable "glue_batch_job_short_name" {
  description = "Name of the Glue CDC Job"
  default     = ""
  type        = string
}

variable "glue_batch_description" {
  description = "Job Description"
  default     = ""
  type        = string
}

variable "glue_batch_create_sec_conf" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS Glue Security Configuration associated with the job."
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
  default     = false
  description = "(Optional) Specifies a standard filter or no filter when you create or edit a job enabled for continuous logging."
}

variable "glue_batch_execution_class" {
  default     = "STANDARD"
  description = "Execution CLass Standard or FLex"
  type        = string
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

variable "glue_batch_job_additional_secret_arns" {
  type        = list(string)
  default     = []
  description = "(Optional) The list of additional secrets this job needs access to."
}

variable "glue_batch_job_connections" {
  type        = list(string)
  default     = []
  description = "The list of Glue connections used for the batch job."
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


# CDC

## Glue job CDC

variable "glue_cdc_arguments" {
  type    = map(any)
  default = {}
}

variable "setup_cdc_job" {
  description = "Enable CDC Job, True or False"
  type        = bool
  default     = false

  validation {
    condition     = var.setup_cdc_job ? !var.batch_only : true
    error_message = "CDC Glue job can only be created when batch_only = false"
  }
}

variable "batch_only" {
  description = "Determines if the pipeline is batch only, True or False?"
  type        = bool
  default     = false
}

variable "glue_cdc_job_name" {
  description = "Name of the Glue CDC Job"
  default     = ""
  type        = string
}

variable "glue_cdc_job_short_name" {
  description = "Name of the Glue CDC Job"
  default     = ""
  type        = string
}

variable "glue_cdc_glue_version" {
  type        = string
  default     = "4.0"
  description = "(Optional) The version of glue to use."
}


variable "glue_cdc_description" {
  description = "Job Description"
  default     = ""
  type        = string
}

variable "glue_cdc_create_sec_conf" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS Glue Security Configuration associated with the job."

  validation {
    condition     = var.glue_cdc_create_sec_conf ? !var.batch_only : true
    error_message = "CDC Glue security configuration can only be created when batch_only = false"
  }
}

variable "glue_cdc_language" {
  type        = string
  default     = "python"
  description = "(Optional) The script programming language."

  validation {
    condition     = contains(["scala", "python"], var.glue_cdc_language)
    error_message = "Accepts a value of 'scala' or 'python'."
  }
}

variable "glue_cdc_temp_dir" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a temporary directory for the job."
}

variable "glue_cdc_checkpoint_dir" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a Checkoint directory for the job."
}

variable "glue_cdc_spark_event_logs" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a Spark Event Logs directory for the job."
}

variable "glue_cdc_script_location" {
  type        = string
  description = "(Optional) Specifies the S3 path to a script that executes a job."
  default     = ""
}

variable "glue_cdc_enable_cont_log_filter" {
  type        = bool
  default     = false
  description = "(Optional) Specifies a standard filter or no filter when you create or edit a job enabled for continuous logging."
}

variable "glue_cdc_execution_class" {
  default     = "STANDARD"
  description = "Execution CLass Standard or FLex"
  type        = string
}

variable "glue_cdc_job_worker_type" {
  type        = string
  default     = "G.025X"
  description = "(Optional) The type of predefined worker that is allocated when a job runs."

  validation {
    condition     = contains(["Standard", "G.025X", "G.1X", "G.2X"], var.glue_cdc_job_worker_type)
    error_message = "Accepts a value of Standard, G.025X, G.1X, or G.2X."
  }
}

variable "glue_cdc_job_num_workers" {
  type        = number
  default     = 2
  description = "(Optional) The number of workers of a defined workerType that are allocated when a job runs."
}

variable "glue_cdc_job_additional_secret_arns" {
  type        = list(string)
  default     = []
  description = "(Optional) The list of additional secrets this job needs access to."
}

variable "glue_cdc_job_connections" {
  type        = list(string)
  default     = []
  description = "The list of Glue connections used for the CDC job."
}

variable "glue_cdc_additional_policies" {
  type        = string
  default     = ""
  description = "(Optional) The list of Policies used for this job."
}

variable "glue_cdc_max_concurrent" {
  type        = number
  default     = 1
  description = "(Optional) The maximum number of concurrent runs allowed for a job."
}

variable "glue_cdc_maintenance_window" {
  type        = string
  description = "The maintenance window during which the glue job will be restarted"
}

variable "glue_cdc_create_role" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS IAM role associated with the job."

  validation {
    condition     = var.glue_cdc_create_role ? !var.batch_only : true
    error_message = "CDC Glue job role can only be created when batch_only = false"
  }
}


# Unprocessed Raw Files Check Job
variable "setup_unprocessed_raw_files_check_job" {
  description = "Enable Job to Check If All Raw Files Have Been Processed, True or False"
  type        = bool
  default     = false

  validation {
    condition     = var.setup_unprocessed_raw_files_check_job ? !var.batch_only : true
    error_message = "Unprocessed raw files check job can only be created when batch_only = false"
  }
}

variable "glue_unprocessed_raw_files_check_job_name" {
  description = "Name of the Glue Unprocessed Raw Files Check Job"
  default     = ""
  type        = string
}

variable "glue_unprocessed_raw_files_check_job_short_name" {
  description = "Name of the Glue Unprocessed Raw Files Check Job"
  default     = ""
  type        = string
}

variable "glue_unprocessed_raw_files_check_job_glue_version" {
  type        = string
  default     = "4.0"
  description = "(Optional) The version of glue to use."
}

variable "glue_unprocessed_raw_files_check_description" {
  description = "Job Description"
  default     = ""
  type        = string
}

variable "glue_unprocessed_raw_files_check_create_sec_conf" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS Glue Security Configuration associated with the job."

  validation {
    condition     = var.glue_unprocessed_raw_files_check_create_sec_conf ? !var.batch_only : true
    error_message = "Glue unprocessed raw files check job security configuration can only be created when batch_only = false"
  }
}

variable "glue_unprocessed_raw_files_check_language" {
  type        = string
  default     = "python"
  description = "(Optional) The script programming language."

  validation {
    condition     = contains(["scala", "python"], var.glue_unprocessed_raw_files_check_language)
    error_message = "Accepts a value of 'scala' or 'python'."
  }
}

variable "glue_unprocessed_raw_files_check_temp_dir" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a temporary directory for the job."
}

variable "glue_unprocessed_raw_files_check_checkpoint_dir" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a Checkoint directory for the job."
}

variable "glue_unprocessed_raw_files_check_spark_event_logs" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a Spark Event Logs directory for the job."
}

variable "glue_unprocessed_raw_files_check_script_location" {
  type        = string
  description = "(Optional) Specifies the S3 path to a script that executes a job."
  default     = ""
}

variable "glue_unprocessed_raw_files_check_enable_cont_log_filter" {
  type        = bool
  default     = false
  description = "(Optional) Specifies a standard filter or no filter when you create or edit a job enabled for continuous logging."
}

variable "glue_unprocessed_raw_files_check_execution_class" {
  default     = "STANDARD"
  description = "Execution CLass Standard or FLex"
  type        = string
}

variable "glue_unprocessed_raw_files_check_job_worker_type" {
  type        = string
  default     = "G.1X"
  description = "(Optional) The type of predefined worker that is allocated when a job runs."

  validation {
    condition     = contains(["Standard", "G.1X", "G.2X"], var.glue_unprocessed_raw_files_check_job_worker_type)
    error_message = "Accepts a value of Standard, G.1X, or G.2X."
  }
}

variable "glue_unprocessed_raw_files_check_job_num_workers" {
  type        = number
  default     = 2
  description = "(Optional) The number of workers of a defined workerType that are allocated when a job runs."
}

variable "glue_unprocessed_raw_files_check_additional_policies" {
  type        = string
  default     = ""
  description = "(Optional) The list of Policies used for this job."
}

variable "glue_unprocessed_raw_files_check_max_concurrent" {
  type        = number
  default     = 1
  description = "(Optional) The maximum number of concurrent runs allowed for a job."
}

variable "glue_unprocessed_raw_files_check_create_role" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS IAM role associated with the job."

  validation {
    condition     = var.glue_unprocessed_raw_files_check_create_role ? !var.batch_only : true
    error_message = "Glue unprocessed raw files check job role can only be created when batch_only = false"
  }
}

variable "glue_unprocessed_raw_files_check_arguments" {
  type    = map(any)
  default = {}
}


# Archive Job
variable "setup_archive_job" {
  description = "Enable Archive Job, True or False"
  type        = bool
  default     = false

  validation {
    condition     = var.setup_archive_job ? !var.batch_only : true
    error_message = "Archive job can only be created when batch_only = false"
  }
}

variable "glue_archive_job_schedule" {
  description = "Cron schedule for the archive job"
  default     = "cron(0 0/3 ? * * *)"
  type        = string
}

variable "glue_archive_job_name" {
  description = "Name of the Glue Archive Job"
  default     = ""
  type        = string
}

variable "glue_archive_job_short_name" {
  description = "Name of the Glue Archive Job"
  default     = ""
  type        = string
}

variable "glue_archive_job_glue_version" {
  type        = string
  default     = "4.0"
  description = "(Optional) The version of glue to use."
}

variable "glue_archive_description" {
  description = "Job Description"
  default     = ""
  type        = string
}

variable "glue_archive_create_sec_conf" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS Glue Security Configuration associated with the job."

  validation {
    condition     = var.glue_archive_create_sec_conf ? !var.batch_only : true
    error_message = "Glue archive job security configuration can only be created when batch_only = false"
  }
}

variable "glue_archive_language" {
  type        = string
  default     = "python"
  description = "(Optional) The script programming language."

  validation {
    condition     = contains(["scala", "python"], var.glue_archive_language)
    error_message = "Accepts a value of 'scala' or 'python'."
  }
}

variable "glue_archive_temp_dir" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a temporary directory for the job."
}

variable "glue_archive_checkpoint_dir" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a Checkoint directory for the job."
}

variable "glue_archive_spark_event_logs" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a Spark Event Logs directory for the job."
}

variable "glue_archive_script_location" {
  type        = string
  description = "(Optional) Specifies the S3 path to a script that executes a job."
  default     = ""
}

variable "glue_archive_enable_cont_log_filter" {
  type        = bool
  default     = false
  description = "(Optional) Specifies a standard filter or no filter when you create or edit a job enabled for continuous logging."
}

variable "glue_archive_execution_class" {
  default     = "STANDARD"
  description = "Execution CLass Standard or FLex"
  type        = string
}

variable "glue_archive_job_worker_type" {
  type        = string
  default     = "G.1X"
  description = "(Optional) The type of predefined worker that is allocated when a job runs."

  validation {
    condition     = contains(["Standard", "G.1X", "G.2X"], var.glue_archive_job_worker_type)
    error_message = "Accepts a value of Standard, G.1X, or G.2X."
  }
}

variable "glue_archive_job_num_workers" {
  type        = number
  default     = 2
  description = "(Optional) The number of workers of a defined workerType that are allocated when a job runs."
}

variable "glue_archive_additional_policies" {
  type        = string
  default     = ""
  description = "(Optional) The list of Policies used for this job."
}

variable "glue_archive_max_concurrent" {
  type        = number
  default     = 1
  description = "(Optional) The maximum number of concurrent runs allowed for a job."
}

variable "glue_archive_create_role" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS IAM role associated with the job."

  validation {
    condition     = var.glue_archive_create_role ? !var.batch_only : true
    error_message = "Glue archive job role can only be created when batch_only = false"
  }
}

variable "glue_archive_arguments" {
  type    = map(any)
  default = {}
}

# Create Reload Diff Job
variable "setup_create_reload_diff_job" {
  description = "Enable Job which creates the reload diff, True or False"
  type        = bool
  default     = false
}

variable "glue_create_reload_diff_job_role" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS IAM role associated with the job."
}

variable "glue_create_reload_diff_job_name" {
  description = "Name of the Glue Create Reload Diff Job"
  default     = ""
  type        = string
}

variable "glue_create_reload_diff_job_short_name" {
  description = "Short name of the Glue Create Reload Diff Job"
  default     = ""
  type        = string
}

variable "glue_create_reload_diff_job_glue_version" {
  type        = string
  default     = "4.0"
  description = "(Optional) The version of glue to use."
}

variable "glue_create_reload_diff_job_description" {
  description = "Job Description"
  default     = ""
  type        = string
}

variable "glue_create_reload_diff_job_create_sec_conf" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS Glue Security Configuration associated with the job."
}

variable "glue_create_reload_diff_job_language" {
  type        = string
  default     = "python"
  description = "(Optional) The script programming language."

  validation {
    condition     = contains(["scala", "python"], var.glue_create_reload_diff_job_language)
    error_message = "Accepts a value of 'scala' or 'python'."
  }
}

variable "glue_create_reload_diff_job_temp_dir" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a temporary directory for the job."
}

variable "glue_create_reload_diff_job_enable_cont_log_filter" {
  type        = bool
  default     = false
  description = "(Optional) Specifies a standard filter or no filter when you create or edit a job enabled for continuous logging."
}

variable "glue_create_reload_diff_job_execution_class" {
  default     = "STANDARD"
  description = "Execution CLass Standard or FLex"
  type        = string
}

variable "glue_create_reload_diff_job_additional_policies" {
  type        = string
  default     = ""
  description = "(Optional) The list of Policies used for this job."
}

variable "glue_create_reload_diff_job_worker_type" {
  type    = string
  default = "G.1X"
}

variable "glue_create_reload_diff_job_num_workers" {
  type    = number
  default = 2
}

variable "glue_create_reload_diff_job_max_concurrent" {
  type    = number
  default = 1
}

variable "glue_create_reload_diff_job_arguments" {
  type    = map(any)
  default = {}
}

variable "glue_create_reload_diff_job_spark_event_logs" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a Spark Event Logs directory for the job."
}

variable "s3_kms_arn" {
  type        = string
  default     = ""
  description = "(Optional) The ARN of the kMS Key associated to S3"
}

variable "glue_log_group_retention_in_days" {
  type        = number
  default     = 7
  description = "(Optional) The default number of days log events retained in the glue job log group."
}

variable "account_region" {
  description = "Current AWS Region."
  default     = "eu-west-2"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID."
  default     = ""
  type        = string
}

# Lambda
variable "setup_step_function_notification_lambda" {
  description = "Enable Step Function Notification Lambda, True or False ?"
  type        = bool
  default     = false
}

variable "step_function_notification_lambda" {
  description = "Name for Notification Lambda Name"
  type        = string
  default     = ""
}

variable "s3_file_transfer_lambda_code_s3_bucket" {
  description = "S3 File Transfer Lambda Code Bucket ID"
  type        = string
  default     = ""
}

variable "reporting_lambda_code_s3_key" {
  description = "S3 File Transfer Lambda Code Bucket KEY"
  type        = string
  default     = ""
}

variable "step_function_notification_lambda_handler" {
  description = "Notification Lambda Handler"
  type        = string
  default     = "uk.gov.justice.digital.lambda.StepFunctionDMSNotificationLambda::handleRequest"
}

variable "step_function_notification_lambda_runtime" {
  description = "Lambda Runtime"
  type        = string
  default     = "java11"
}

variable "step_function_notification_lambda_policies" {
  description = "An List of Notification Lambda Policies"
  type        = list(string)
  default     = []
}

variable "step_function_notification_lambda_tracing" {
  description = "Lambda Tracing"
  type        = string
  default     = "Active"
}

variable "step_function_notification_lambda_trigger" {
  description = "Name for Notification Lambda Trigger Name"
  type        = string
  default     = ""
}

variable "lambda_subnet_ids" {
  description = "Lambda Subnet ID's"
  type        = list(string)
  default     = []
}

variable "lambda_security_group_ids" {
  description = "Lambda Security Group ID's"
  type        = list(string)
  default     = []
}

variable "env" {
  type        = string
  description = "Env Type"
}

variable "script_version" {
  type = string
}
variable "jar_version" {
  type = string
}

variable "enable_spark_ui" {
  type        = string
  default     = "true"
  description = "UI Enabled by default, override with False"
}
