variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the LBC configuration"
  type        = string
}

variable "account_id" {
  description = "AWS account ID (for KMS policy)"
  type        = string
}

variable "is_production" {
  description = "Whether this is a production environment (for Gatekeeper config)"
  type        = string
  default     = "false"
}

variable "environment_name" {
  description = "Terraform workspace / environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
