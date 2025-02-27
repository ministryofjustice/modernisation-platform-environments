variable "cluster_arn" {
  description = "The ARN of the EKS cluster"
  type        = string
  default     = null
}

variable "iam_role_arn" {
  description = "The ARN of the analytical_platform_ui_service_role"
  type        = string
  default     = null
}

variable "arn" {
  description = "The ARN of the managed_prometheus_kms_access_iam_policy"
  type        = string
  default     = null
}
