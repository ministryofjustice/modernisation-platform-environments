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
