variable collaborator_access {
  type        = string
  default     = "developer"
  description = "Collaborators must specify which access level they are using, eg set an environment varable of export TF_VAR_collaborator_access=migration"
}



variable project_id {
  type        = string
  description = "(Required) Project Short ID that will be used for resources."
}

variable short_name {
  type        = string
  description = "(Required) Short name of the project."
}

variable environment {
  type        = string
  description = "(Required) Environment name."
}

variable region {
  type = string
}

variable account_id {
  type = string
}

variable tags {
  type = map(string)
}

variable availability_zone {
  type = string
}


variable migration_type {
  type = string
}


# Networking

variable networking {
  type = list(any)
}

variable vpc {
  type = string
}

variable vpc_security_group_ids {
  type = list(string)
}

variable vpc_security_group_id {
  type = string
}

variable vpc_cidr_blocks{
  type = string
}

variable vpc_role_dependency {
  type = any
}

variable subnet_ids {
    type = list(string)
}

# DMS - Source

variable source_database {
  type = object({
    endpoint_id   = string
    endpoint_type = string
    engine_name   = string
    username      = string
    password      = string
    server_name   = string
    port          = number
    database_name = string
  })
}

variable source_database_name {
  type = string
}

variable source_endpoint_id {
  type = string
}

variable source_password {
  type = string
}

variable source_username {
  type = string
}

variable source_server_name {
  type = string
}

variable dms_source_name {
  type = string
}

variable database_name {
  type = string
}


variable setup_dms_endpoints {
  type = bool
  default = true
}

variable setup_dms_s3_endpoint {
  type = bool
  default = true
}




variable dms_kms_source_cmk {
  default = null
  description = "The ARN of the KMS Key to use when encrypting data for DMS source endpoint"
  type = object({
    arn = string
  })
}

variable flow_log_cloudwatch_log_group_kms_key_id {
  description = "The ARN of the KMS Key to use when encrypting log data for VPC flow logs"
  type        = string
  default     = null
}


# DMS - General

variable setup_dms_instance {
  type = bool
  default = true
}

variable endpoint_id {
  type = string
}

# DMS - Replication

variable replication_instance_class {
  type = string
}

variable replication_task_id {
  type = string
}

variable replication_instance_arn {
  type = string
}

variable replication_instance_storage {
  type = string
}

variable replication_instance_version {
  type = string
}

variable replication_instance_maintenance_window {
  type = string
}

variable replication_instance_id {
  type = string
}

variable replication_subnet_group_id {
  type = string
}

variable replication_instance_name {
  type = string
}

variable enable_replication_task {
  type = bool
  default = true
}

# S3 target

variable dms_target_name {
  type = string
}

variable s3_bucket {
  type = string
}

variable bucket_name {
  type = string
}
