
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "datadog_integration_external_id" {
  description = "The external ID for the Datadog integration"
  type        = string
}

variable "datadog_api_kpi_secret_name" {
  description = "The name of the Secret that will hold the Datadog Api Key."
  type        = string
  default     = "DdApiKeySecret-hN6hCIq7xwr1"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the AWS KMS key to be used to encrypt secret values."
}

variable "kms_key_id" {
  description = "The ARN of the KMS key to use for encryption"
  type        = string
  default     = null
}

variable "environment" {
  description = "The environment for the log-groups"
  type        = string
}

variable "enable_datadog_agent_apm" {
  description = "Enable the Datadog agent"
  type        = bool
  default     = false
}

variable "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  type        = string
}

variable "ecs_subnet_ids" {
  description = "The subnet IDs for the ECS cluster"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "The security group ID for the ECS cluster"
  type        = string
}

variable "ecs_task_iam_role_name" {
  description = "The name of the IAM role for the ECS task"
  type        = string
}

variable "ecs_task_iam_role_arn" {
  description = "The ARN of the IAM role for the ECS task"
  type        = string
}

variable "ecs_task_exec_iam_role_arn" {
  description = "The ARN of the IAM role for the ECS task execution"
  type        = string
}

variable "aws_account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "agent_datadog_memory" {
  description = "The memory for the Datadog agent"
  type        = number
  default     = 512
}

variable "agent_datadog_cpu" {
  description = "The CPU for the Datadog agent"
  type        = number
  default     = 128
}

variable "agent_datadog_container_cpu" {
  description = "The CPU for the Datadog agent container"
  type        = number
  default     = 100
}

variable "agent_datadog_container_memory" {
  description = "The memory for the Datadog agent container"
  type        = number
  default     = 512
}
