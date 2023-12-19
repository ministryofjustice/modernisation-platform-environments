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
}

variable "dms_target_name" {
  type = string
}

variable "short_name" {
  type = string
}

variable "bucket_name" {
  type = string
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

variable "source_address" {}

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

variable "source_app_password" {
  description = "Password for the endpoint to access the source database"
}

variable "source_app_username" {
  description = "Username for the endpoint to access the source database"
}

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

variable "arguments" {
  type    = map(any)
  default = {}
}

variable "setup_cdc_job" {
  description = "Enable CDC Job, True or False"
  type        = bool
  default     = false  
}

variable "glue_job_name" {
  description = "Name of the Glue CDC Job"
  default     = ""  
}

variable "glue_job_short_name" {
  description = "Name of the Glue CDC Job"
  default     = ""  
}

variable "description" {
  description = "Job Description"
  default     = ""  
}

variable "create_sec_conf" {
  type        = bool
  default     = false
  description = "(Optional) Create AWS Glue Security Configuration associated with the job."
}

variable "log_group_retention_in_days" {
  type        = number
  default     = 1
  description = "(Optional) The default number of days log events retained in the glue job log group."
}


variable "language" {
  type        = string
  default     = "python"
  description = "(Optional) The script programming language."

  validation {
    condition     = contains(["scala", "python"], var.language)
    error_message = "Accepts a value of 'scala' or 'python'."
  }
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

variable "script_location" {
  type        = string
  description = "(Optional) Specifies the S3 path to a script that executes a job."
  default     = ""
}

variable "enable_cont_log_filter" {
  type        = bool
  default     = true
  description = "(Optional) Specifies a standard filter or no filter when you create or edit a job enabled for continuous logging."
}

variable "s3_kms_arn" {
  type        = string
  default     = ""
  description = "(Optional) The ARN of the kMS Key associated to S3"
}

variable "execution_class" {
  default     = "STANDARD"
  description = "Execution CLass Standard or FLex"
}

variable "reporting_hub_cdc_job_worker_type" {
  type        = string
  default     = "G.1X"
  description = "(Optional) The type of predefined worker that is allocated when a job runs."

  validation {
    condition     = contains(["Standard", "G.1X", "G.2X"], var.reporting_hub_cdc_job_worker_type)
    error_message = "Accepts a value of Standard, G.1X, or G.2X."
  }
}

variable "reporting_hub_cdc_job_num_workers" {
  type        = number
  default     = 2
  description = "(Optional) The number of workers of a defined workerType that are allocated when a job runs."
}

variable "additional_policies" {
  type        = string
  default     = ""
  description = "(Optional) The list of Policies used for this job."
}

variable "max_concurrent" {
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