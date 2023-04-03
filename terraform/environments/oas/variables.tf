variable "iam_role_arn" {
  type        = string
  description = "IAM role ARN for the AWS Backup service role"
}

variable "tags" {
  default     = {}
  description = "Tags to apply to resources, where applicable"
  type        = map(any)
}