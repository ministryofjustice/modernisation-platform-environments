variable "enable_cloudwatch_read_only_access" {
  type        = bool
  description = "Enable CloudWatchReadOnlyAccess managed policy"
  default     = true
}

variable "enable_amazon_prometheus_query_access" {
  type        = bool
  description = "Enable AmazonPrometheusQueryAccess managed policy"
  default     = false
}

variable "enable_aws_xray_read_only_access" {
  type        = bool
  description = "Enable AWSXrayReadOnlyAccess managed policy"
  default     = false
}

variable "additional_policies" {
  type        = map(string)
  description = "ARNs of any additional policies to attach to the IAM role"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
