variable "env_name" {
  description = "The name of the env where file system is being created"
  type        = string
}

variable "account_config" {
  description = "account config to pass to the instance"
  type        = any
}

variable "tags" {
  description = "tags to add for all resources"
  type        = map(string)
  default = {
  }
}

variable "account_info" {
  description = "Account info to pass to the instance"
  type        = any
}

variable "ldap_config" {
  description = "ldap config to pass to the instance"
  type        = any
}

variable "platform_vars" {
  type = object({
    environment_management = any
  })
}

variable "source_security_group_id" {
  description = "sg of source"
  type        = string
  default     = null
}

variable "environment_config" {
  description = "environment config to pass to the instance"
  type        = any
}

variable "bastion_sg_id" {
  description = "Security group id of the bastion"
  type        = string
}

variable "enable_platform_backups" {
  description = "Enable or disable Mod Platform centralised backups"
  type        = bool
  default     = null
}

variable "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  type        = string
}

variable "task_role_arn" {
  description = "The ARN of the task role"
  type        = string
}

variable "sns_topic_arn" {
  description = "The ARN of the SNS topic"
  type        = string
}
