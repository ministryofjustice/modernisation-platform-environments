variable "env_name" {
  type = string
}

variable "app_name" {
  type = string
}

# Account level info
variable "account_info" {
  type = any
}

variable "account_config" {
  type = any
}

variable "environment_config" {
  type = any
}

variable "bastion_config" {
  type = any
}

variable "bcs_config" {
  type = any
}

variable "bps_config" {
  type = any
}

variable "bws_config" {
  type = any
}

variable "boe_efs_config" {
  type    = any
  default = null
}

variable "dis_config" {
  description = "Configuration for DIS instances"
  type = object({
    instance_count           = number
    ami_name                 = string
    computer_name            = string
    ebs_volumes              = any
    ebs_volumes_config       = any
    instance_config          = any
    powershell_branch        = optional(string, "main")
    cloudwatch_metric_alarms = optional(any, null)
  })
  default = null
}

variable "tags" {
  type = any
}

variable "platform_vars" {
  type = object({
    environment_management = any
  })
}

variable "dsd_db_config" {
  type = any
}

variable "boe_db_config" {
  type = any
}

variable "mis_db_config" {
  type = any
}

variable "fsx_config" {
  type = any
}

variable "auto_config" {
  type    = any
  default = null #optional
}

variable "dfi_config" {
  description = "Configuration for DFI instances"
  type = object({
    instance_count           = number
    ami_name                 = string
    ebs_volumes              = any
    ebs_volumes_config       = any
    instance_config          = any
    branch                   = optional(string, "main")
    cloudwatch_metric_alarms = optional(any, null)
  })
  default = null #optional
}

variable "dfi_report_bucket_config" {
  type    = any
  default = null #optional
}

variable "deploy_oracle_stats" {
  description = "for deploying Oracle stats bucket"
  default     = true
  type        = bool
}

variable "environments_in_account" {
  type    = list(string)
  default = []
}

variable "pagerduty_integration_key" {
  description = "PagerDuty integration key"
  type        = string
  default     = null
}

variable "lb_config" {
  description = "params for Classic Load Balancer"
  type        = any
  default     = null
}

variable "datasync_config" {
  description = "Configuration for DataSync agent and task to sync S3 to FSX"
  type = object({
    source_s3_bucket_arn       = string
    source_s3_subdirectory     = optional(string, "/dfinterventions/dfi/csv/reports/")
    fsx_domain                 = optional(string, "delius-mis-dev.internal")
    bandwidth_throttle         = optional(number)
    schedule_expression        = optional(string, "cron(15 4 * * ? *)") # Default: DataSync at 04:15 UTC
    lambda_schedule_expression = optional(string, "cron(0 4 * * ? *)")  # Default: Lambda at 04:00 UTC
  })
  default = null
}

# Only create one per account
variable "create_backup_role" {
  description = "Role used to run AWS Backups i.e. AWSBackupDefaultServiceRole"
  type        = bool
  default     = false
}
