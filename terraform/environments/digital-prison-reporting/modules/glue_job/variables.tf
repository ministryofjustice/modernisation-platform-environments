variable "create_job" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS IAM role associated with the job."
}

variable "arguments" {
  type    = map(any)
  default = {}
}

variable "max_concurrent" {
  default = 1
}

variable "dpu" {
  default = 1
}

variable "temp_dir" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a temporary directory for the job."
}

variable "checkpoint_dir" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a Checkoint directory for the job."
}

variable "spark_event_logs" {
  type        = string
  default     = null
  description = "(Optional) Specifies an Amazon S3 path to a bucket that can be used as a Spark Event Logs directory for the job."
}

variable "bookmark" {
  default     = "disabled"
  description = "It can be enabled, disabled or paused."
}

variable "bookmark_options" {
  type = map(any)

  default = {
    enabled  = "job-bookmark-enable"
    disabled = "job-bookmark-disable"
    paused   = "job-bookmark-pause"
  }
}

variable "name" {
  type        = string
  description = "(Required) Name that will be used for identify resources."
}

variable "project_id" {
  type        = string
  description = "(Required) Project Short ID that will be used for resources."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}


variable "script_location" {
  type        = string
  description = "(Optional) Specifies the S3 path to a script that executes a job."
}

variable "command_type" {
  type        = string
  default     = "glueetl"
  description = "(Optional) Specifies the command type. Either glueetl or gluestreaming."
}

variable "python_version" {
  type        = number
  default     = 3
  description = "(Optional) The Python version being used to execute a Python shell job."

  validation {
    condition     = contains([2, 3], var.python_version)
    error_message = "Allowed values are 2 or 3."
  }
}

variable "connections" {
  type        = list(string)
  default     = []
  description = "(Optional) The list of connections used for this job."
}

variable "additional_policies" {
  type        = string
  default     = ""
  description = "(Optional) The list of Policies used for this job."
}

variable "description" {
  type        = string
  default     = ""
  description = "(Optional) Description of the job."
}

variable "max_concurrent_runs" {
  type        = number
  default     = 1
  description = "(Optional) The maximum number of concurrent runs allowed for a job."
}

variable "glue_version" {
  type        = string
  default     = "4.0"
  description = "(Optional) The version of glue to use."
}

variable "max_retries" {
  type        = number
  default     = 0
  description = "(Optional) The maximum number of times to retry this job if it fails."
}

variable "notify_delay_after" {
  type        = number
  default     = null
  description = "(Optional) After a job run starts, the number of minutes to wait before sending a job run delay notification."
}

variable "role_arn" {
  type        = string
  default     = ""
  description = "(Optional) The ARN of the IAM role associated with this job."
}

variable "role_name" {
  type        = string
  default     = ""
  description = "(Optional) The Name of the IAM role associated with this job."
}

variable "aws_kms_key" {
  type        = string
  default     = ""
  description = "(Optional) The ARN of the kMS Key associated to S3"
}

variable "create_role" {
  type        = bool
  default     = true
  description = "(Optional) Create AWS IAM role associated with the job."
}

variable "timeout" {
  type        = number
  default     = 120
  description = "(Optional) The job timeout in minutes."
}

variable "execution_class" {
  default     = "STANDARD"
  description = "Execution CLass Standard or FLex"
}

variable "worker_type" {
  type        = string
  default     = "G.1X"
  description = "(Optional) The type of predefined worker that is allocated when a job runs."

  validation {
    condition     = contains(["Standard", "G.1X", "G.2X"], var.worker_type)
    error_message = "Accepts a value of Standard, G.1X, or G.2X."
  }
}

variable "number_of_workers" {
  type        = number
  default     = 2
  description = "(Optional) The number of workers of a defined workerType that are allocated when a job runs."
}


variable "security_configuration" {
  type        = string
  default     = ""
  description = "(Optional) The name of the Security Configuration to be associated with the job."
}

variable "create_security_configuration" {
  type        = bool
  default     = true
  description = "(Optional) Create AWS Glue Security Configuration associated with the job."
}

variable "security_configuration_cloudwatch_encryption" {
  type = object({
    cloudwatch_encryption_mode = string
    kms_key_arn                = string
  })
  default = {
    cloudwatch_encryption_mode = "DISABLED"
    kms_key_arn                = null
  }
  description = "(Optional) A cloudwatch_encryption block which contains encryption configuration for CloudWatch."
}

variable "security_configuration_job_bookmarks_encryption" {
  type = object({
    job_bookmarks_encryption_mode = string
    kms_key_arn                   = string
  })
  default = {
    job_bookmarks_encryption_mode = "DISABLED"
    kms_key_arn                   = null
  }
  description = "(Optional) A job_bookmarks_encryption block which contains encryption configuration for job bookmarks."
}

variable "security_configuration_s3_encryption" {
  type = object({
    s3_encryption_mode = string
    kms_key_arn        = string
  })
  default = {
    s3_encryption_mode = "DISABLED"
    kms_key_arn        = null
  }
  description = "(Optional) A s3_encryption block which contains encryption configuration for S3 data."
}


variable "log_group_retention_in_days" {
  type        = number
  default     = 7
  description = "(Optional) The default number of days log events retained in the glue job log group."
}


variable "job_language" {
  type        = string
  default     = "python"
  description = "(Optional) The script programming language."

  validation {
    condition     = contains(["scala", "python"], var.job_language)
    error_message = "Accepts a value of 'scala' or 'python'."
  }
}

variable "class" {
  type        = string
  default     = null
  description = "(Optional) The Scala class that serves as the entry point for your Scala script."
}

variable "extra_py_files" {
  type        = list(string)
  default     = []
  description = "(Optional) The Amazon S3 paths to additional Python modules that AWS Glue adds to the Python path before executing your script."
}

variable "extra_jars" {
  type        = list(string)
  default     = []
  description = "(Optional) The Amazon S3 paths to additional Java .jar files that AWS Glue adds to the Java classpath before executing your script."
}

variable "user_jars_first" {
  type        = bool
  default     = null
  description = "(Optional) Prioritizes the customer's extra JAR files in the classpath."
}

variable "use_postgres_driver" {
  type        = bool
  default     = null
  description = "(Optional) Prioritizes the Postgres JDBC driver in the class path to avoid a conflict with the Amazon Redshift JDBC driver."
}

variable "extra_files" {
  type        = list(string)
  default     = []
  description = "(Optional) The Amazon S3 paths to additional files, such as configuration files that AWS Glue copies to the working directory of your script before executing it."
}

variable "job_bookmark_option" {
  type        = string
  default     = "job-bookmark-disable"
  description = "(Optional) Controls the behavior of a job bookmark."

  validation {
    condition     = contains(["job-bookmark-enable", "job-bookmark-disable", "job-bookmark-pause"], var.job_bookmark_option)
    error_message = "Accepts a value of 'job-bookmark-enable', 'job-bookmark-disable' or 'job-bookmark-pause'."
  }
}

variable "enable_metrics" {
  type        = bool
  default     = false
  description = "(Optional) Enables the collection of metrics for job profiling for job run."
}

variable "enable_continuous_cloudwatch_log" {
  type        = bool
  default     = false
  description = "(Optional) Enables real-time continuous logging for AWS Glue jobs."
}

variable "enable_continuous_log_filter" {
  type        = bool
  default     = true
  description = "(Optional) Specifies a standard filter or no filter when you create or edit a job enabled for continuous logging."
}

variable "continuous_log_stream_prefix" {
  type        = string
  default     = null
  description = "(Optional) Specifies a custom CloudWatch log stream prefix for a job enabled for continuous logging."
}

variable "create_kinesis_ingester" {
  type        = bool
  default     = false
  description = "Whether to create Kinesis Stream"
}