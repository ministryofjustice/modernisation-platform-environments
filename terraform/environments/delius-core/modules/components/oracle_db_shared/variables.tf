variable "env_name" {
  description = "Environment name short ie dev"
  type        = string
}

variable "app_name" {
  type = string
}

variable "tags" {
  description = "Tags to apply to the instance"
  type        = map(string)
}

variable "environment_config" {
  type = any
}

variable "account_config" {
  description = "Account config to pass to the instance"
  type        = any
}

variable "account_info" {
  description = "Account info to pass to the instance"
  type        = any
}

variable "platform_vars" {
  description = "Platform vars to pass to the instance"
  type        = any
}

variable "public_keys" {
  description = "Public keys to add to the instance"
  type        = map(any)
}

variable "bastion_sg_id" {
  description = "Security group id of the bastion"
  type        = string
}

variable "deploy_oracle_stats" {
  description = "for deploying Oracle stats bucket"
  default     = true
  type        = bool
}

variable "db_suffix" {
  description = "identifier to append to name e.g. dsd, boe"
  type        = string
  default     = "db"
}

variable "database_name" {
  type = string
}

variable "database_port" {
  type = number
}

variable "oracle_db_server_names" {
  type = object({
    primarydb  = string
    standbydb1 = string
    standbydb2 = string
  })
}

variable "sns_topic_arn" {
  description = "The ARN of the SNS topic"
  type        = string
}

variable "cluster_security_group_id" {
  description = "Security group id for the cluster"
  type        = string
}

variable "delius_microservice_configs" {
  type = any
}

variable "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  type        = string
}
