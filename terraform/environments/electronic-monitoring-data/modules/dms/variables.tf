variable "database_name" {
  description = "Name of the database to be migrated"
  type        = string
}

variable "local_tags" {
  description = "The predefined local.tags"
  type        = map(string)
}
# ---------------------------------------------------------

# Source Endpoint Variables
variable "rds_db_security_group_id" {
  description = "Security Group associated to RDS Database Instance"
  type        = string
}

variable "rds_db_instance_pasword" {
  description = "Password for the RDS Database Instance"
  type        = string
}

variable "rds_db_instance_port" {
  description = "Logical port number for the RDS Database Instance"
  type        = number
}

variable "rds_db_server_name" {
  description = "RDS Database Instance endpoint"
  type        = string
}

variable "rds_db_username" {
  description = "Username to login to RDS Database Instance"
  type        = string
}
# ---------------------------------------------------------

# Target Endpoint Variables
variable "ep_service_access_role_arn" {
  description = "DMS Endpoint Service Access Role-ARN"
  type        = string
}

variable "target_s3_bucket_name" {
  description = "DMS S3 Target Endpoint Bucket Name"
  type        = string
}
# ---------------------------------------------------------

# Migration Task Variables
variable "rep_task_settings_filepath" {
  description = "JSON file with DMS relevant migration task settings"
  type        = string
}

variable "rep_task_table_mapping_filepath" {
  description = "JSON file with DMS table mappings"
  type        = string
}

variable "dms_replication_instance_arn" {
  description = "Assign the Replication Instance-ARN to be used"
  type        = string
}

variable "event_bridge_rule_name" {
    description = "Name of the event rule"
    type        = string
}

variable "event_bridge_role_name" {
    description = "Name of the event rule"
    type        = string
}

variable "dms_trigger_state" {
    description = "DMS task state"
    type = string
    default = "COMPLETED"
}

variable "dms_validation_step_function_arn" {
    description = "DMS Validation Step Function Arn"
    type = string
}
