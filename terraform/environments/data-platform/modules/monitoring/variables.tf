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
