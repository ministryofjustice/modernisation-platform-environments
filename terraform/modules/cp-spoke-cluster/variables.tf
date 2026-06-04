variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.35"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Whether the EKS API endpoint is publicly accessible"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 30
}

variable "node_pools" {
  description = "Auto Mode node pools to enable"
  type        = list(string)
  default     = ["general-purpose", "system"]
}

variable "access_entries" {
  description = "EKS access entries map"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
