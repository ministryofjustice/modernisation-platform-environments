variable "networking" {

  type = list(any)

}

variable "collaborator_access" {
  type        = string
  default     = "developer"
  description = "Collaborators must specify which access level they are using, eg set an environment variable of export TF_VAR_collaborator_access=migration"
}

variable "source_database" {
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

variable "s3_bucket" {
  type = string
}

variable "replication_instance_class" {
  type = string
}

variable "replication_task_id" {
  type = string
}

variable "replication_instance_arn" {
  type = string
}

variable "source_database_name" {
  type = string
}

variable "source_endpoint_id" {
  type = string
}

variable "source_password" {
  type = string
}

variable "source_username" {
  type = string
}

variable "source_server_name" {
  type = string
}

variable "replication_instance_id" {
  type = string
}

variable "replication_subnet_group_id" {
  type = string
}

# make a variable from dms_kms_source_cmk in kms-keys.tf

variable "dms_kms_source_cmk" {
  default = null
  description = "The ARN of the KMS Key to use when encrypting data for DMS source endpoint"
  type = object({
    arn = string
  })
}

variable "flow_log_cloudwatch_log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data for VPC flow logs"
  type        = string
  default     = null
}

variable "database_name" {
  type = string
}