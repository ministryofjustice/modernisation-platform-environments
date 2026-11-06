variable "additional_policies" {
  type        = map(string)
  description = "ARNs of any additional policies to attach to the IAM role"
  default     = {}
}
