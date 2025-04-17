
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

variable "enable_datadog_agent_apm" {
  description = "Enable the Datadog agent"
  type        = bool
  default     = false
}

variable "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  type        = string
  default     = ""
}
