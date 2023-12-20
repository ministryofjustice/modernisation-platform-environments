variable "dms_source_endpoint" {
  type        = string
  default     = ""
}

variable "dms_target_endpoint" {
  type        = string
  default     = ""
}

variable "name" {
  description = "DMS Replication name."
}

variable "enable_replication_task" {
  description = "Enable DMS Replication Task, True or False"
  type        = bool
  default     = false
}

variable "setup_dms_instance" {
  description = "Enable DMS Instance, True or False"
  type        = bool
  default     = false
}

variable "project_id" {
  type        = string
  description = "(Required) Project Short ID that will be used for resources."
}

variable "env" {
  type        = string
  description = "Env Type"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Key-value map of resource tags."
}

variable "extra_attributes" {
  type    = string
  default = null
}

variable "dms_source_name" {
  type = string
  default = ""
}

variable "dms_target_name" {
  type = string
  default = ""
}

variable "short_name" {
  type = string
  default = ""
}

variable "migration_type" {
  type        = string
  description = "DMS Migration Type"
}

variable "availability_zones" {
  default = [
    {
      0 = "eu-west-2a"
    }
  ]
}

variable "rename_rule_source_schema" {
  description = "The source schema we will rename to a target output 'space'"
  type        = string
}

variable "rename_rule_output_space" {
  description = "The name of the target output 'space' that the source schema will be renamed to"
  type        = string
}


variable "subnet_ids" {
  description = "An List of VPC subnet IDs to use in the subnet group"
  type        = list(string)
  default     = []
}

variable "vpc" {}

variable "availability_zone" {
  default = null
}

variable "create" {
  default = true
}

variable "create_iam_roles" {
  default = true
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the role"
  type        = string
  default     = null
}

# Used in tagginga and naming the resources

variable "stack_name" {
  description = "The name of our application"
  default     = "dblink"
}

variable "owner" {
  description = "A group email address to be used in tags"
  default     = "autobots@ga.gov.au"
}

#--------------------------------------------------------------
# DMS general config
#--------------------------------------------------------------

variable "identifier" {
  default     = "rds"
  description = "Name of the database in the RDS"
}

#--------------------------------------------------------------
# DMS target config
#--------------------------------------------------------------

variable "target_backup_retention_period" {
  # Days
  default     = "30"
  description = "Retention of RDS backups"
}

variable "target_backup_window" {
  default     = "14:00-17:00"
  description = "RDS backup window"
}

variable "target_db_port" {
  description = "The port the Application Server will access the database on"
  default     = 5432
}

variable "target_engine_version" {
  description = "Engine version"
  default     = "9.3.14"
}

variable "target_instance_class" {
  default     = "db.t2.micro"
  description = "Instance class"
}

variable "target_maintenance_window" {
  default     = "Mon:00:00-Mon:03:00"
  description = "RDS maintenance window"
}

variable "target_rds_is_multi_az" {
  description = "Create backup database in separate availability zone"
  default     = "false"
}

variable "target_storage" {
  default     = "10"
  description = "Storage size in GB"
}

variable "target_storage_encrypted" {
  description = "Encrypt storage or leave unencrypted"
  default     = false
}

#variable "target_username" {
#  description = "Username to access the target database"
#}

#--------------------------------------------------------------
# DMS source config
#--------------------------------------------------------------
variable "source_backup_retention_period" {
  # Days
  default     = "1"
  description = "Retention of RDS backups"
}

variable "source_backup_window" {
  # 12:00AM-03:00AM AEST
  default     = "14:00-17:00"
  description = "RDS backup window"
}

variable "source_db_name" {
  description = "Name of the target database"
  default     = "oracle"
}

variable "source_db_port" {
  description = "The port the Application Server will access the database on"
  default     = null
}

variable "source_engine" {
  default     = "oracle-se2"
  description = "Engine type, example values mysql, postgres"
}

variable "source_engine_name" {
  default     = ""
  description = "Engine name for DMS"
}

variable "source_engine_version" {
  description = "Engine version"
  default     = "12.1.0.2.v8"
}

variable "source_instance_class" {
  default     = "db.t2.micro"
  description = "Instance class"
}

variable "source_maintenance_window" {
  default     = "Mon:00:00-Mon:03:00"
  description = "RDS maintenance window"
}

variable "source_password" {
  description = "Password of the source database"
  default     = ""
}

variable "source_rds_is_multi_az" {
  description = "Create backup database in separate availability zone"
  default     = "false"
}

variable "source_storage" {
  default     = "10"
  description = "Storage size in GB"
}

variable "source_storage_encrypted" {
  description = "Encrypt storage or leave unencrypted"
  default     = false
}

variable "source_username" {
  description = "Username to access the source database"
  default     = ""
}

#--------------------------------------------------------------
# DMS Replication Instance
#--------------------------------------------------------------

variable "replication_instance_maintenance_window" {
  description = "Maintenance window for the replication instance"
  default     = "sun:10:30-sun:14:30"
}

variable "replication_instance_storage" {
  description = "Size of the replication instance in GB"
  default     = "10"
}

variable "replication_instance_version" {
  description = "Engine version of the replication instance"
  default     = "3.4.6"
}

variable "replication_instance_class" {
  description = "Instance class of replication instance"
  default     = "dms.t2.micro"
}

#--------------------------------------------------------------
# Network
#--------------------------------------------------------------

variable "database_subnet_cidr" {
  default     = ["10.26.25.208/28", "10.26.25.224/28", "10.26.25.240/28"]
  description = "List of subnets to be used for databases"
}

variable "vpc_cidr" {
  description = "CIDR for the  VPC"
  type        = list(string)
  default     = null
}

# Dummy Depends on
variable "vpc_role_dependency" {
  # the value doesn't matter; we're just using this variable
  # to propagate dependencies.
  type    = any
  default = []
}

variable "cloudwatch_role_dependency" {
  # the value doesn't matter; we're just using this variable
  # to propagate dependencies.
  type    = any
  default = []
}

variable "table_mappings" {
  type = any
}

variable "replication_task_settings" {
  type = any
}

## Glue job CDC

variable "glue_cdc_arguments" {
  type    = map(any)
  default = {}
}

variable "setup_cdc_job" {
  description = "Enable CDC Job, True or False"
  type        = bool
  default     = false  
}

variable "glue_cdc_job_name" {
  description = "Name of the Glue CDC Job"
  default     = ""  
}

variable "glue_cdc_job_short_name" {
  description = "Name of the Glue CDC Job"
  default     = ""  
}

variable "glue_cdc_description" {
  description = "Job Description"
  default     = ""  
}

variable "glue_cdc_create_sec_conf" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS Glue Security Configuration associated with the job."
}

variable "glue_cdc_log_group_retention_in_days" {
  type        = number
  default     = 1
  description = "(Optional) The default number of days log events retained in the glue job log group."
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
  default     = true
  description = "(Optional) Specifies a standard filter or no filter when you create or edit a job enabled for continuous logging."
}

variable "s3_kms_arn" {
  type        = string
  default     = ""
  description = "(Optional) The ARN of the kMS Key associated to S3"
}

variable "glue_cdc_execution_class" {
  default     = "STANDARD"
  description = "Execution CLass Standard or FLex"
}

variable "glue_cdc_job_worker_type" {
  type        = string
  default     = "G.1X"
  description = "(Optional) The type of predefined worker that is allocated when a job runs."

  validation {
    condition     = contains(["Standard", "G.1X", "G.2X"], var.glue_cdc_job_worker_type)
    error_message = "Accepts a value of Standard, G.1X, or G.2X."
  }
}

variable "glue_cdc_job_num_workers" {
  type        = number
  default     = 2
  description = "(Optional) The number of workers of a defined workerType that are allocated when a job runs."
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

variable "account_region" {
  description = "Current AWS Region."
  default     = "eu-west-2"
}

variable "account_id" {
  description = "AWS Account ID."
  default     = ""
}

variable "glue_cdc_create_role" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS IAM role associated with the job."
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

variable "reporting_lambda_code_s3_key"{
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

# STEP FUNCTION, Pipeline
variable "setup_data_ingestion_pipeline"  {
  description = "Enable Data Ingestion Pipeline, True or False ?"
  type        = bool
  default     = false
}

variable "data_ingestion_pipeline"  {
  description = "Name for Data Ingestion Pipeline"
  type        = string
  default     = ""  
}

variable "pipeline_dms_task_time_out"  {
  description = "DMS Task Timeout"
  type        = number
  default     = 300
}

variable "pipeline_additional_policies" {
  description = "Pipeline Additional policies"
  type        = list(string)
  default     = []
}

variable "dms_replication_task_arn" {
  type        = string
  default     = ""  
}

variable "pipeline_notification_lambda_function" {
  description = "Pipeline Notification Lambda Name"
  type        = string
  default     = ""  
}

variable "glue_reporting_hub_batch_jobname" {
  description = "Glue Reporting Hub Batch JobName"
  type        = string
  default     = ""  
}

variable "glue_reporting_hub_cdc_jobname" {
  description = "Glue Reporting Hub CDC JobName"
  type        = string
  default     = ""  
}

variable "s3_raw_bucket_id" {
  description = "S3, RAW Bucket ID"
  type        = string
  default     = ""  
}

variable "s3_raw_archive_bucket_id" {
  description = "S3, RAW Archive Bucket ID"
  type        = string
  default     = ""  
}

variable "s3_file_transfer_lambda_function" {
  description = "S3 File Transfer Lambda Function Name"
  type        = string
  default     = "" 
}

variable "glue_hive_table_creation_jobname" {
  description = "Glue Hive Table Creation JobName"
  type        = string
  default     = "" 
}

## Glue job BATCH

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
