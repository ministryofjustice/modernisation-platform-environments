variable "account_id" {
  description = "AWS account ID hosting the service"
  type        = string
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt service data"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by the service"
  type        = list(string)
}

variable "region" {
  description = "AWS region hosting the service"
  type        = string
}

variable "resource_application_name" {
  description = "Name used for service resources"
  type        = string
}

variable "service_configuration" {
  description = "ECS runtime configuration"
  type = object({
    bootstrap_image_tag = string
    container_port      = number
    desired_count       = number
    health_check_path   = string
    task_cpu            = number
    task_memory         = number
  })
}

variable "tags" {
  description = "Tags applied to service resources"
  type        = map(string)
}

variable "vpc" {
  description = "VPC details used by the service"
  type = object({
    cidr_block = string
    id         = string
  })
}
